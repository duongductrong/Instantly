import AppKit
import SwiftUI

@Observable
final class ExpandedWindowViewModel: NSObject, NSSpeechSynthesizerDelegate {
    var expandedWidth: CGFloat = DesignTokens.expandedWidth
    var queryText: String = ""
    var attachments: [AttachmentItem] = []
    var statusMessage: String = ""
    var isLoading: Bool = false
    var contextItems: [ContextItem] = []
    var messages: [ChatMessage] = []
    var speakingMessageID: UUID?
    var shouldFocusInput: Bool = false

    private var streamTask: Task<Void, Never>?
    private var capturedContextItems: [ContextItem] = []
    private let speechSynthesizer = NSSpeechSynthesizer()

    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }

    struct AttachmentItem: Identifiable {
        let id = UUID()
        let filename: String
        let icon: String
    }

    // MARK: - Context Management

    func setContext(_ items: [ContextItem]) {
        contextItems = items
        capturedContextItems = items
    }

    func removeContextItem(_ item: ContextItem) {
        contextItems.removeAll { $0.id == item.id }
    }

    func clearContext() {
        contextItems.removeAll()
        capturedContextItems.removeAll()
    }

    @discardableResult
    func addCapturedActiveAppContext() -> Bool {
        guard let item = capturedContextItems.first(where: { $0.type == .activeApp }) else { return false }
        return appendContextIfNeeded(item)
    }

    @discardableResult
    func addCapturedSelectedTextContext() -> Bool {
        guard let item = capturedContextItems.first(where: { $0.type == .selectedText }) else {
            return false
        }
        return appendContextIfNeeded(item)
    }

    @discardableResult
    func addClipboardContext() -> Bool {
        guard let raw = NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !raw.isEmpty
        else { return false }

        let truncated = raw.count > 80 ? String(raw.prefix(77)) + "..." : raw
        let item = ContextItem(
            type: .selectedText,
            label: truncated,
            rawValue: raw,
            icon: nil,
            bundleIdentifier: nil
        )
        return appendContextIfNeeded(item)
    }

    func canAddCapturedActiveAppContext() -> Bool {
        guard let item = capturedContextItems.first(where: { $0.type == .activeApp }) else { return false }
        return !hasDuplicateContext(for: item)
    }

    func canAddCapturedSelectedTextContext() -> Bool {
        guard let item = capturedContextItems.first(where: { $0.type == .selectedText }) else { return false }
        return !hasDuplicateContext(for: item)
    }

    func canAddClipboardContext() -> Bool {
        guard let raw = NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !raw.isEmpty
        else { return false }
        return !contextItems.contains {
            $0.type == .selectedText && normalizedText($0.rawValue) == raw
        }
    }

    // MARK: - Chat

    func sendMessage() {
        let text = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let settings = SettingsService.shared.settings
        let context = filteredContextItems(using: settings.assistant)
        let systemPrompt = buildSystemPrompt(
            assistantPrompt: settings.assistant.systemPrompt,
            context: context
        )

        queryText = ""
        requestInputFocus()
        statusMessage = ""
        messages.append(ChatMessage(role: .user, content: text))
        messages.append(ChatMessage(role: .assistant, content: ""))
        isLoading = true

        guard settings.model.selectedProvider == .ollama else {
            if var last = messages.last, last.role == .assistant {
                last.content = "This provider is configured, but runtime integration is pending."
                messages[messages.count - 1] = last
            }
            isLoading = false
            return
        }

        let currentMessages = messages.filter { $0.role != .assistant || !$0.content.isEmpty }
        let ollamaConfig = settings.model.ollamaRuntimeConfig

        streamTask = Task { @MainActor in
            do {
                let stream = OllamaChatService.sendStreamingChat(
                    messages: currentMessages,
                    config: ollamaConfig,
                    systemPrompt: systemPrompt
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
        stopSpeaking()
        messages.removeAll()
        statusMessage = ""
        requestInputFocus()
    }

    func requestInputFocus() {
        shouldFocusInput = true
    }

    func copyMessageContent(_ message: ChatMessage) {
        let text = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func toggleSpeakMessageContent(_ message: ChatMessage) {
        let text = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if speakingMessageID == message.id, speechSynthesizer.isSpeaking {
            stopSpeaking()
            return
        }

        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking()
        }

        speakingMessageID = message.id
        let started = speechSynthesizer.startSpeaking(text)
        if !started {
            speakingMessageID = nil
        }
    }

    func isMessageSpeaking(_ message: ChatMessage) -> Bool {
        speakingMessageID == message.id && speechSynthesizer.isSpeaking
    }

    func speechSynthesizer(_ sender: NSSpeechSynthesizer, didFinishSpeaking finishedSpeaking: Bool) {
        speakingMessageID = nil
    }

    // MARK: - Window Size

    func resetExpandedWidth() {
        expandedWidth = DesignTokens.expandedWidth
    }

    func toggleExpandedWidth() {
        let isDefaultWidth = expandedWidth == DesignTokens.expandedWidth
        expandedWidth = isDefaultWidth ? DesignTokens.expandedToggledWidth : DesignTokens.expandedWidth
    }

    private func appendContextIfNeeded(_ item: ContextItem) -> Bool {
        guard !hasDuplicateContext(for: item) else { return false }
        contextItems.append(item)
        return true
    }

    private func hasDuplicateContext(for item: ContextItem) -> Bool {
        switch item.type {
        case .activeApp:
            return contextItems.contains {
                $0.type == .activeApp && $0.bundleIdentifier == item.bundleIdentifier
            }
        case .selectedText:
            guard let raw = normalizedText(item.rawValue) else { return false }
            return contextItems.contains {
                $0.type == .selectedText && normalizedText($0.rawValue) == raw
            }
        }
    }

    private func filteredContextItems(using assistantSettings: AssistantSettings) -> [ContextItem] {
        contextItems.filter { item in
            switch item.type {
            case .activeApp:
                assistantSettings.includeActiveAppContext
            case .selectedText:
                assistantSettings.includeSelectedTextContext
            }
        }
    }

    private func buildSystemPrompt(assistantPrompt: String, context: [ContextItem]) -> String {
        let basePrompt = assistantPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        var parts: [String] = [
            basePrompt.isEmpty
                ? AssistantSettings.defaultValue.systemPrompt
                : basePrompt,
        ]

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

        return parts.joined(separator: "\n")
    }

    private func normalizedText(_ text: String?) -> String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }

    private func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking()
        }
        speakingMessageID = nil
    }
}
