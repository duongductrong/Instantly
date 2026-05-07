import AppKit
import SwiftUI

/// View model for the inline result bubble that streams LLM output for content-modifying actions.
@Observable
@MainActor
final class InlineResultViewModel {
    var resultText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var actionLabel: String = ""
    var actionIcon: String = ""

    private var streamTask: Task<Void, Never>?
    private var sourceApp: NSRunningApplication?
    private var sourceBundleID: String?

    /// Starts streaming the LLM response for the given action and selected text.
    func run(action: QuickToolbarAction, selectedText: String, sourceApp: NSRunningApplication?) {
        self.sourceApp = sourceApp
        actionLabel = action.label
        actionIcon = action.icon
        sourceBundleID = sourceApp?.bundleIdentifier
        resultText = ""
        errorMessage = nil
        isLoading = true

        let settings = SettingsService.shared.settings
        let provider = settings.model.defaultInlineProvider
        let runtimeConfig = settings.model.runtimeConfig(for: provider)
        let userMessage = ChatMessage(role: .user, content: action.inlinePrompt + selectedText)

        streamTask = Task { @MainActor in
            do {
                let stream = ChatProviderService.sendStreamingChat(
                    messages: [userMessage],
                    provider: provider,
                    runtimeConfig: runtimeConfig,
                    systemPrompt: "You are a text editing assistant. Return ONLY the modified text, with no explanations, no markdown formatting, and no surrounding quotes."
                )
                for try await token in stream {
                    guard !Task.isCancelled else { break }
                    resultText += token
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    /// Replaces the selected text in the source app with the result.
    func applyResult() {
        let text = resultText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Activate the source app first so paste targets it
        if let app = sourceApp {
            app.activate()
        }

        // Short delay to let the app activate, then paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            ActiveAppContextService.replaceSelectedText(
                with: text,
                bundleIdentifier: self.sourceBundleID
            )
        }
    }

    func cancel() {
        streamTask?.cancel()
        streamTask = nil
        isLoading = false
    }
}
