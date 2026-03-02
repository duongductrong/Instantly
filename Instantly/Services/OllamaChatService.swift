import Foundation

enum OllamaChatService {
    private static let baseURL = "http://localhost:11434"
    private static let model = "llama3.1"

    // MARK: - Error Types

    enum ChatError: LocalizedError {
        case serverUnavailable
        case modelNotFound
        case invalidResponse(String)
        case requestFailed(Int)

        var errorDescription: String? {
            switch self {
            case .serverUnavailable:
                "Cannot connect to Ollama. Make sure it's running on localhost:11434."
            case .modelNotFound:
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
    }

    private struct MessagePayload: Encodable {
        let role: String
        let content: String
    }

    private struct ChatStreamChunk: Decodable {
        let message: MessageContent
        let done: Bool
    }

    private struct MessageContent: Decodable {
        let content: String
    }

    // MARK: - Health Check

    static func isAvailable() async -> Bool {
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
        context: [ContextItem]
    )
        -> AsyncThrowingStream<String, Error>
    {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let url = URL(string: "\(baseURL)/api/chat")!

                    var payloadMessages: [MessagePayload] = []

                    // Build system message from context
                    let systemPrompt = buildSystemMessage(from: context)
                    if !systemPrompt.isEmpty {
                        payloadMessages.append(MessagePayload(role: "system", content: systemPrompt))
                    }

                    // Add conversation messages (skip system role from history)
                    for msg in messages where msg.role != .system {
                        payloadMessages.append(MessagePayload(role: msg.role.rawValue, content: msg.content))
                    }

                    let requestBody = ChatRequest(model: model, messages: payloadMessages, stream: true)

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONEncoder().encode(requestBody)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw ChatError.invalidResponse("Not an HTTP response")
                    }

                    switch httpResponse.statusCode {
                    case 200: break
                    case 404: throw ChatError.modelNotFound
                    default: throw ChatError.requestFailed(httpResponse.statusCode)
                    }

                    for try await line in bytes.lines {
                        try Task.checkCancellation()

                        guard let data = line.data(using: .utf8) else { continue }
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
                } catch let error as URLError where error.code == .cannotConnectToHost
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

    // MARK: - System Message

    private static func buildSystemMessage(from context: [ContextItem]) -> String {
        var parts = ["You are a helpful AI assistant called Instantly."]

        for item in context {
            switch item.type {
            case .activeApp:
                parts.append("Active app: \(item.label)")
            case .selectedText:
                if let raw = item.rawValue {
                    parts.append("Selected text:\n\(raw)")
                }
            }
        }

        return parts.count > 1 ? parts.joined(separator: "\n") : parts[0]
    }
}
