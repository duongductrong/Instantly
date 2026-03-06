import SwiftUI

struct AssistantSettingsView: View {
    private let settingsService = SettingsService.shared

    @State private var draft: AssistantSettings = .defaultValue

    private var hasChanges: Bool {
        draft != settingsService.settings.assistant
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("System prompt")
                        .font(.system(size: 13, weight: .medium))

                    TextEditor(text: $draft.systemPrompt)
                        .font(.system(size: 13))
                        .frame(minHeight: 80, maxHeight: 160)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                }
            } header: {
                Text("Prompt")
            }

            Section {
                Toggle(isOn: $draft.includeActiveAppContext) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include active app context")
                        Text("Sends the name of the currently focused application")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $draft.includeSelectedTextContext) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include selected text context")
                        Text("Sends any selected text as additional context")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Context")
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("New chat shortcut")
                        Text("Shortcut to clear the conversation and start fresh")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    HotkeyRecorderButton(
                        binding: draft.newChatShortcut,
                        onRecord: { newBinding in
                            draft.newChatShortcut = newBinding
                        }
                    )
                }
            } header: {
                Text("Shortcuts")
            }

            Section {
                HStack {
                    Button("Reset Assistant to Defaults") {
                        settingsService.resetAssistantToDefaults()
                        draft = settingsService.settings.assistant
                    }

                    Spacer()

                    Button("Save") {
                        settingsService.updateAssistant { $0 = draft }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasChanges)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            draft = settingsService.settings.assistant
        }
    }
}
