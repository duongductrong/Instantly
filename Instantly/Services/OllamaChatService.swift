import Foundation

enum OllamaChatService {
    // MARK: - Error Types

    enum ChatError: LocalizedError {
        case invalidBaseURL
        case serverUnavailable
        case modelNotFound(String)
        case invalidResponse(String)
        case requestFailed(Int)

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                "Ollama base URL is invalid."
            case .serverUnavailable:
                "Cannot connect to Ollama. Make sure it is running and reachable."
            case let .modelNotFound(model):
                "Model \(model) not found. Run: ollama pull \(model)"
            case let .invalidResponse(detail):
                "Invalid response from Ollama: \(detail)"
            case let .requestFailed(code):
                "Request failed with status \(code)"
            }
        }
    }

    // MARK: - Request/Response

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [MessagePayload]
        let stream: Bool
        let options: ChatOptions
    }

    private struct MessagePayload: Encodable {
        let role: String
        let content: String
    }

    private struct ChatOptions: Encodable {
        let temperature: Double
        let numPredict: Int

        enum CodingKeys: String, CodingKey {
            case temperature
            case numPredict = "num_predict"
        }
    }

    private struct ChatStreamChunk: Decodable {
        let message: MessageContent
        let done: Bool
    }

    private struct MessageContent: Decodable {
        let content: String
    }

    // MARK: - Health Check

    static func isAvailable(baseURL: String) async -> Bool {
        guard let url = URL(string: baseURL) else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Streaming Chat

    static func sendStreamingChat(
        messages: [ChatMessage],
        config: OllamaProviderConfig,
        systemPrompt: String
    )
        -> AsyncThrowingStream<String, Error>
    {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let baseURL = config.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let url = URL(string: "\(baseURL)/api/chat") else {
                        throw ChatError.invalidBaseURL
                    }

                    var payloadMessages: [MessagePayload] = []

                    let trimmedSystemPrompt = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedSystemPrompt.isEmpty {
                        payloadMessages.append(MessagePayload(role: "system", content: trimmedSystemPrompt))
                    }

                    // Add conversation messages (skip system role from history).
                    for message in messages where message.role != .system {
                        payloadMessages.append(
                            MessagePayload(
                                role: message.role.rawValue,
                                content: message.content
                            )
                        )
                    }

                    let requestBody = ChatRequest(
                        model: config.model,
                        messages: payloadMessages,
                        stream: true,
                        options: ChatOptions(
                            temperature: config.temperature,
                            numPredict: config.maxTokens
                        )
                    )

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONEncoder().encode(requestBody)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw ChatError.invalidResponse("Not an HTTP response")
                    }

                    switch httpResponse.statusCode {
                    case 200:
                        break
                    case 404:
                        throw ChatError.modelNotFound(config.model)
                    default:
                        throw ChatError.requestFailed(httpResponse.statusCode)
                    }

                    for try await line in bytes.lines {
                        try Task.checkCancellation()
                        guard let data = line.data(using: .utf8), !data.isEmpty else { continue }

                        let chunk = try JSONDecoder().decode(ChatStreamChunk.self, from: data)
                        if !chunk.message.content.isEmpty {
                            continuation.yield(chunk.message.content)
                        }

                        if chunk.done {
                            break
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
}
