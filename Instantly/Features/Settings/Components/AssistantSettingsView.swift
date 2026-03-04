import SwiftUI

struct AssistantSettingsView: View {
    private let settingsService = SettingsService.shared

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("System prompt")
                        .font(.system(size: 13, weight: .medium))

                    TextEditor(text: Binding(
                        get: { settingsService.settings.assistant.systemPrompt },
                        set: { value in settingsService.updateAssistant { $0.systemPrompt = value } }
                    ))
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
                Toggle(isOn: Binding(
                    get: { settingsService.settings.assistant.includeActiveAppContext },
                    set: { value in settingsService.updateAssistant { $0.includeActiveAppContext = value } }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include active app context")
                        Text("Sends the name of the currently focused application")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: Binding(
                    get: { settingsService.settings.assistant.includeSelectedTextContext },
                    set: { value in settingsService.updateAssistant { $0.includeSelectedTextContext = value } }
                )) {
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
                        binding: settingsService.settings.assistant.newChatShortcut,
                        onRecord: { newBinding in
                            settingsService.updateAssistant { $0.newChatShortcut = newBinding }
                        }
                    )
                }
            } header: {
                Text("Shortcuts")
            }

            Section {
                Button("Reset Assistant to Defaults") {
                    settingsService.resetAssistantToDefaults()
                }
            }
        }
        .formStyle(.grouped)
    }
}
