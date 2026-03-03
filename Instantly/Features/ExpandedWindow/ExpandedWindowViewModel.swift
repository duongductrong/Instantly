import SwiftUI

@Observable
final class ExpandedWindowViewModel {
    var expandedWidth: CGFloat = DesignTokens.expandedWidth
    var queryText: String = ""
    var attachments: [AttachmentItem] = []
    var statusMessage: String = ""
    var isLoading: Bool = false
    var contextItems: [ContextItem] = []
    var messages: [ChatMessage] = []

    private var streamTask: Task<Void, Never>?

    struct AttachmentItem: Identifiable {
        let id = UUID()
        let filename: String
        let icon: String
    }

    // MARK: - Context Management

    func setContext(_ items: [ContextItem]) {
        contextItems = items
    }

    func removeContextItem(_ item: ContextItem) {
        contextItems.removeAll { $0.id == item.id }
    }

    func clearContext() {
        contextItems.removeAll()
    }

    // MARK: - Chat

    func sendMessage() {
        let text = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        queryText = ""
        statusMessage = ""
        messages.append(ChatMessage(role: .user, content: text))
        messages.append(ChatMessage(role: .assistant, content: ""))
        isLoading = true

        let currentMessages = messages.filter { $0.role != .assistant || !$0.content.isEmpty }
        let context = contextItems

        streamTask = Task { @MainActor in
            do {
                let stream = OllamaChatService.sendStreamingChat(
                    messages: currentMessages,
                    context: context
                )
                for try await token in stream {
                    guard !Task.isCancelled else { break }
                    if var last = messages.last, last.role == .assistant {
                        last.content += token
                        messages[messages.count - 1] = last
                    }
                }
            } catch {
                statusMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func stopGenerating() {
        streamTask?.cancel()
        streamTask = nil
        isLoading = false
    }

    func clearConversation() {
        stopGenerating()
        messages.removeAll()
        statusMessage = ""
    }

    // MARK: - Window Size

    func resetExpandedWidth() {
        expandedWidth = DesignTokens.expandedWidth
    }

    func toggleExpandedWidth() {
        let isDefaultWidth = expandedWidth == DesignTokens.expandedWidth
        expandedWidth = isDefaultWidth ? DesignTokens.expandedToggledWidth : DesignTokens.expandedWidth
    }
}
