import Foundation

/// Service for streaming chat completions via the Anthropic Claude API.
enum ClaudeChatService {
    // MARK: - Error Types

    enum ChatError: LocalizedError {
        case invalidBaseURL
        case serverUnavailable
        case invalidResponse(String)
        case requestFailed(Int, String?)
        case missingAPIKey

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                "Claude base URL is invalid."
            case .serverUnavailable:
                "Cannot connect to Claude API."
            case let .invalidResponse(detail):
                "Invalid response from Claude: \(detail)"
            case let .requestFailed(code, message):
                if let message, !message.isEmpty {
                    "Request failed (\(code)): \(message)"
                } else {
                    "Request failed with status \(code)"
                }
            case .missingAPIKey:
                "Claude API key is required."
            }
        }
    }

    // MARK: - Request/Response

    private struct ChatRequest: Encodable {
        let model: String
        let maxTokens: Int
        let messages: [MessagePayload]
        let system: String?
        let stream: Bool

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case messages
            case system
            case stream
        }
    }

    private struct MessagePayload: Encodable {
        let role: String
        let content: String
    }

    private struct ChatStreamEvent: Decodable {
        let type: String
        let delta: DeltaContent?
    }

    private struct DeltaContent: Decodable {
        let type: String?
        let text: String?
    }

    // MARK: - Streaming Chat

    static func sendStreamingChat(
        messages: [ChatMessage],
        config: ClaudeProviderConfig,
        apiKey: String,
        systemPrompt: String,
        maxTokens: Int
    )
        -> AsyncThrowingStream<String, Error>
    {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        throw ChatError.missingAPIKey
                    }

                    let trimmedBaseURL = config.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                    let normalizedBaseURL = trimmedBaseURL
                        .hasSuffix("/") ? String(trimmedBaseURL.dropLast()) : trimmedBaseURL
                    guard let url = URL(string: "\(normalizedBaseURL)/messages") else {
                        throw ChatError.invalidBaseURL
                    }

                    var payloadMessages: [MessagePayload] = []

                    for message in messages where message.role != .system {
                        payloadMessages.append(
                            MessagePayload(
                                role: message.role.rawValue,
                                content: message.content
                            )
                        )
                    }

                    let trimmedSystemPrompt = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

                    let requestBody = ChatRequest(
                        model: config.model,
                        maxTokens: maxTokens,
                        messages: payloadMessages,
                        system: trimmedSystemPrompt.isEmpty ? nil : trimmedSystemPrompt,
                        stream: true
                    )

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("\(apiKey)", forHTTPHeaderField: "x-api-key")
                    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    request.httpBody = try JSONEncoder().encode(requestBody)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw ChatError.invalidResponse("Not an HTTP response")
                    }

                    if httpResponse.statusCode != 200 {
                        let errorBody = await collectErrorBody(from: bytes)
                        throw ChatError.requestFailed(httpResponse.statusCode, errorBody)
                    }

                    for try await line in bytes.lines {
                        try Task.checkCancellation()
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))
                        guard jsonString != "[DONE]" else { continue }
                        guard let data = jsonString.data(using: .utf8), !data.isEmpty else { continue }

                        let event = try JSONDecoder().decode(ChatStreamEvent.self, from: data)
                        if event.type == "content_block_delta",
                           let text = event.delta?.text, !text.isEmpty
                        {
                            continuation.yield(text)
                        }
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch let error as URLError where
                    error.code == .cannotConnectToHost
                    || error.code == .cannotFindHost
                    || error.code == .networkConnectionLost
                {
                    continuation.finish(throwing: ChatError.serverUnavailable)
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Helpers

    private static func collectErrorBody(from bytes: URLSession.AsyncBytes) async -> String? {
        var data = Data()
        do {
            for try await byte in bytes {
                data.append(byte)
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = json["error"] as? [String: Any],
               let msg = err["message"] as? String
            {
                return msg
            }
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
