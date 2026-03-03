import SwiftUI

struct AssistantSettingsSectionView: View {
    let settings: AssistantSettings
    let onSystemPromptChanged: (String) -> Void
    let onIncludeActiveAppContextChanged: (Bool) -> Void
    let onIncludeSelectedTextContextChanged: (Bool) -> Void
    let onShortcutChanged: (HotkeyBinding) -> Void
    let onReset: () -> Void

    @State private var promptDraft: String = ""

    var body: some View {
        Form {
            Section("Behavior") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("System Prompt")
                        .font(.system(size: 12, weight: .medium))

                    TextEditor(text: $promptDraft)
                        .font(.system(size: 12))
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 140)
                        .background(Color.white.opacity(0.08))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Toggle("Include active app context", isOn: Binding(
                    get: { settings.includeActiveAppContext },
                    set: onIncludeActiveAppContextChanged
                ))

                Toggle("Include selected text context", isOn: Binding(
                    get: { settings.includeSelectedTextContext },
                    set: onIncludeSelectedTextContextChanged
                ))
            }

            Section("Shortcuts") {
                ShortcutRecorderField(
                    title: "New Chat Shortcut",
                    subtitle: "Clear current conversation in expanded window.",
                    shortcut: Binding(
                        get: { settings.newChatShortcut },
                        set: onShortcutChanged
                    )
                )
            }

            Section {
                Button("Reset Assistant Defaults", role: .destructive) {
                    onReset()
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .onAppear {
            promptDraft = settings.systemPrompt
        }
        .onChange(of: settings.systemPrompt) { _, newValue in
            if promptDraft != newValue {
                promptDraft = newValue
            }
        }
        .onChange(of: promptDraft) { _, newValue in
            onSystemPromptChanged(newValue)
        }
    }
}
