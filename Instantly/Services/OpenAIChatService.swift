import Foundation

/// Service for streaming chat completions via OpenAI-compatible APIs.
/// Covers OpenAI official API and any provider exposing the `/v1/chat/completions` endpoint.
enum OpenAIChatService {
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
                "Base URL is invalid."
            case .serverUnavailable:
                "Cannot connect to the API server."
            case let .invalidResponse(detail):
                "Invalid response: \(detail)"
            case let .requestFailed(code, message):
                if let message, !message.isEmpty {
                    "Request failed (\(code)): \(message)"
                } else {
                    "Request failed with status \(code)"
                }
            case .missingAPIKey:
                "API key is required."
            }
        }
    }

    // MARK: - Request/Response

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [MessagePayload]
        let stream: Bool
        let temperature: Double
        let maxTokens: Int?

        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case stream
            case temperature
            case maxTokens = "max_tokens"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(model, forKey: .model)
            try container.encode(messages, forKey: .messages)
            try container.encode(stream, forKey: .stream)
            try container.encode(temperature, forKey: .temperature)
            if let maxTokens {
                try container.encode(maxTokens, forKey: .maxTokens)
            }
        }
    }

    private struct MessagePayload: Encodable {
        let role: String
        let content: String
    }

    private struct ChatStreamChunk: Decodable {
        let choices: [StreamChoice]?
    }

    private struct StreamChoice: Decodable {
        let delta: DeltaContent?
    }

    private struct DeltaContent: Decodable {
        let content: String?
    }

    // MARK: - Streaming Chat

    static func sendStreamingChat(
        messages: [ChatMessage],
        config: OpenAIProviderConfig,
        apiKey: String,
        systemPrompt: String
    )
        -> AsyncThrowingStream<String, Error>
    {
        sendStreamingChat(
            messages: messages,
            baseURL: config.baseURL,
            model: config.model,
            apiKey: apiKey,
            systemPrompt: systemPrompt,
            temperature: nil,
            maxTokens: nil
        )
    }

    static func sendStreamingChat(
        messages: [ChatMessage],
        config: CustomProviderConfig,
        apiKey: String,
        systemPrompt: String,
        temperature: Double,
        maxTokens: Int
    )
        -> AsyncThrowingStream<String, Error>
    {
        sendStreamingChat(
            messages: messages,
            baseURL: config.baseURL,
            model: config.model,
            apiKey: apiKey,
            systemPrompt: systemPrompt,
            temperature: temperature,
            maxTokens: maxTokens
        )
    }

    private static func sendStreamingChat(
        messages: [ChatMessage],
        baseURL: String,
        model: String,
        apiKey: String,
        systemPrompt: String,
        temperature: Double?,
        maxTokens: Int?
    )
        -> AsyncThrowingStream<String, Error>
    {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        throw ChatError.missingAPIKey
                    }

                    let trimmedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                    let normalizedBaseURL = trimmedBaseURL
                        .hasSuffix("/") ? String(trimmedBaseURL.dropLast()) : trimmedBaseURL
                    guard let url = URL(string: "\(normalizedBaseURL)/chat/completions") else {
                        throw ChatError.invalidBaseURL
                    }

                    var payloadMessages: [MessagePayload] = []

                    let trimmedSystemPrompt = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedSystemPrompt.isEmpty {
                        payloadMessages.append(MessagePayload(role: "system", content: trimmedSystemPrompt))
                    }

                    for message in messages where message.role != .system {
                        payloadMessages.append(
                            MessagePayload(
                                role: message.role.rawValue,
                                content: message.content
                            )
                        )
                    }

                    var requestBody = ChatRequest(
                        model: model,
                        messages: payloadMessages,
                        stream: true,
                        temperature: temperature ?? AppSettings.defaultTemperature,
                        maxTokens: maxTokens
                    )

                    // Some providers don't support max_tokens; omit if nil
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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

                        let chunk = try JSONDecoder().decode(ChatStreamChunk.self, from: data)
                        if let content = chunk.choices?.first?.delta?.content, !content.isEmpty {
                            continuation.yield(content)
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
