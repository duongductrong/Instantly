import SwiftUI

struct ModelSettingsSectionView: View {
    let settings: ModelSettings
    @Binding var openAIAPIKey: String
    @Binding var claudeAPIKey: String
    @Binding var customAPIKey: String
    let validationMessage: String
    let keychainMessage: String

    let onProviderChanged: (ProviderKind) -> Void
    let onOllamaBaseURLChanged: (String) -> Void
    let onOllamaModelChanged: (String) -> Void
    let onOpenAIBaseURLChanged: (String) -> Void
    let onOpenAIModelChanged: (String) -> Void
    let onClaudeModelChanged: (String) -> Void
    let onCustomProviderLabelChanged: (String) -> Void
    let onCustomBaseURLChanged: (String) -> Void
    let onCustomModelChanged: (String) -> Void
    let onTemperatureChanged: (Double) -> Void
    let onMaxTokensChanged: (Int) -> Void

    var body: some View {
        Form {
            Section("Provider") {
                Picker(
                    "Provider",
                    selection: Binding(
                        get: { settings.selectedProvider },
                        set: onProviderChanged
                    )
                ) {
                    ForEach(ProviderKind.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                .pickerStyle(.segmented)

                switch settings.selectedProvider {
                case .ollama:
                    providerField(
                        title: "Base URL",
                        text: settings.ollama.baseURL,
                        prompt: "http://localhost:11434",
                        onChange: onOllamaBaseURLChanged
                    )
                    providerField(
                        title: "Model",
                        text: settings.ollama.model,
                        prompt: "llama3.1",
                        onChange: onOllamaModelChanged
                    )
                case .openAI:
                    providerSecureField(title: "API Key", text: $openAIAPIKey)
                    providerField(
                        title: "Base URL",
                        text: settings.openAI.baseURL,
                        prompt: "https://api.openai.com/v1",
                        onChange: onOpenAIBaseURLChanged
                    )
                    providerField(
                        title: "Model",
                        text: settings.openAI.model,
                        prompt: "gpt-4.1-mini",
                        onChange: onOpenAIModelChanged
                    )
                case .claude:
                    providerSecureField(title: "API Key", text: $claudeAPIKey)
                    providerField(
                        title: "Model",
                        text: settings.claude.model,
                        prompt: "claude-3-7-sonnet-latest",
                        onChange: onClaudeModelChanged
                    )
                case .custom:
                    providerField(
                        title: "Provider Label",
                        text: settings.custom.providerLabel,
                        prompt: "My Provider",
                        onChange: onCustomProviderLabelChanged
                    )
                    providerSecureField(title: "API Key", text: $customAPIKey)
                    providerField(
                        title: "Base URL",
                        text: settings.custom.baseURL,
                        prompt: "https://api.example.com/v1",
                        onChange: onCustomBaseURLChanged
                    )
                    providerField(
                        title: "Model",
                        text: settings.custom.model,
                        prompt: "model-name",
                        onChange: onCustomModelChanged
                    )
                }

                if settings.selectedProvider != .ollama {
                    Text("Configured. Runtime integration pending.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Generation") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Temperature: \(settings.temperature, specifier: "%.2f")")
                        .font(.system(size: 12, weight: .medium))

                    Slider(
                        value: Binding(
                            get: { settings.temperature },
                            set: onTemperatureChanged
                        ),
                        in: 0 ... 2,
                        step: 0.05
                    )
                }

                HStack(spacing: 10) {
                    Text("Max Tokens")
                    TextField(
                        "2048",
                        value: Binding(
                            get: { settings.maxTokens },
                            set: onMaxTokensChanged
                        ),
                        format: .number
                    )
                    .settingsInputStyle()

                    Stepper("", value: Binding(
                        get: { settings.maxTokens },
                        set: onMaxTokensChanged
                    ), in: 256 ... 64_000, step: 256)
                        .labelsHidden()
                }
            }

            if !validationMessage.isEmpty {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red.opacity(0.9))
                }
            }

            if !keychainMessage.isEmpty {
                Section {
                    Text(keychainMessage)
                        .foregroundStyle(.red.opacity(0.9))
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private func providerField(
        title: String,
        text: String,
        prompt: String,
        onChange: @escaping (String) -> Void
    )
        -> some View
    {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))

            TextField(prompt, text: Binding(get: { text }, set: onChange))
                .settingsInputStyle()
        }
    }

    private func providerSecureField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))

            SecureField("Enter API key", text: text)
                .settingsInputStyle()
        }
    }
}
