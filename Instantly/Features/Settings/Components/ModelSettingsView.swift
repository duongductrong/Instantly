import SwiftUI

struct ModelSettingsView: View {
    private let settingsService = SettingsService.shared

    @State private var apiKeyText: String = ""
    @State private var showingAPIKey = false

    var body: some View {
        Form {
            Section {
                Picker("Provider", selection: Binding(
                    get: { settingsService.settings.model.selectedProvider },
                    set: { value in settingsService.updateModel { $0.selectedProvider = value } }
                )) {
                    ForEach(ProviderKind.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
            } header: {
                Text("Provider")
            }

            providerConfigSection

            Section {
                HStack {
                    Text("Temperature")
                    Spacer()
                    Text(String(format: "%.1f", settingsService.settings.model.temperature))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 32)
                }
                Slider(
                    value: Binding(
                        get: { settingsService.settings.model.temperature },
                        set: { value in settingsService.updateModel { $0.temperature = value } }
                    ),
                    in: 0 ... 2,
                    step: 0.1
                )

                HStack {
                    Text("Max tokens")
                    Spacer()
                    TextField("", value: Binding(
                        get: { settingsService.settings.model.maxTokens },
                        set: { value in settingsService.updateModel { $0.maxTokens = value } }
                    ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                }
            } header: {
                Text("Parameters")
            }

            if let errorMessage = settingsService.validateCurrentModelConfiguration() {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 12))
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            loadAPIKey()
        }
        .onChange(of: settingsService.settings.model.selectedProvider) { _, _ in
            loadAPIKey()
            showingAPIKey = false
        }
    }

    // MARK: - Provider Config

    @ViewBuilder
    private var providerConfigSection: some View {
        let provider = settingsService.settings.model.selectedProvider

        Section {
            switch provider {
            case .ollama:
                ollamaConfig
            case .openAI:
                openAIConfig
            case .claude:
                claudeConfig
            case .custom:
                customConfig
            }

            if provider.requiresAPIKey {
                apiKeyField(for: provider)
            }
        } header: {
            Text("\(provider.title) Configuration")
        }
    }

    private var ollamaConfig: some View {
        Group {
            HStack {
                Text("Base URL")
                Spacer()
                TextField("http://localhost:11434", text: Binding(
                    get: { settingsService.settings.model.ollama.baseURL },
                    set: { value in settingsService.updateModel { $0.ollama.baseURL = value } }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
            }

            HStack {
                Text("Model")
                Spacer()
                TextField("llama3.1", text: Binding(
                    get: { settingsService.settings.model.ollama.model },
                    set: { value in settingsService.updateModel { $0.ollama.model = value } }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
            }
        }
    }

    private var openAIConfig: some View {
        Group {
            HStack {
                Text("Base URL")
                Spacer()
                TextField("https://api.openai.com/v1", text: Binding(
                    get: { settingsService.settings.model.openAI.baseURL },
                    set: { value in settingsService.updateModel { $0.openAI.baseURL = value } }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
            }

            HStack {
                Text("Model")
                Spacer()
                TextField("gpt-4.1-mini", text: Binding(
                    get: { settingsService.settings.model.openAI.model },
                    set: { value in settingsService.updateModel { $0.openAI.model = value } }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
            }
        }
    }

    private var claudeConfig: some View {
        HStack {
            Text("Model")
            Spacer()
            TextField("claude-3-7-sonnet-latest", text: Binding(
                get: { settingsService.settings.model.claude.model },
                set: { value in settingsService.updateModel { $0.claude.model = value } }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 220)
        }
    }

    private var customConfig: some View {
        Group {
            HStack {
                Text("Provider label")
                Spacer()
                TextField("My Provider", text: Binding(
                    get: { settingsService.settings.model.custom.providerLabel },
                    set: { value in settingsService.updateModel { $0.custom.providerLabel = value } }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
            }

            HStack {
                Text("Base URL")
                Spacer()
                TextField("https://...", text: Binding(
                    get: { settingsService.settings.model.custom.baseURL },
                    set: { value in settingsService.updateModel { $0.custom.baseURL = value } }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
            }

            HStack {
                Text("Model")
                Spacer()
                TextField("model-name", text: Binding(
                    get: { settingsService.settings.model.custom.model },
                    set: { value in settingsService.updateModel { $0.custom.model = value } }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
            }
        }
    }

    // MARK: - API Key Field

    private func apiKeyField(for provider: ProviderKind) -> some View {
        HStack {
            Text("API Key")
            Spacer()
            Group {
                if showingAPIKey {
                    TextField("sk-...", text: $apiKeyText)
                } else {
                    SecureField("sk-...", text: $apiKeyText)
                }
            }
            .textFieldStyle(.roundedBorder)
            .frame(width: 180)
            .onChange(of: apiKeyText) { _, newValue in
                settingsService.setAPIKey(newValue, for: provider)
            }

            Button {
                showingAPIKey.toggle()
            } label: {
                Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func loadAPIKey() {
        let provider = settingsService.settings.model.selectedProvider
        apiKeyText = settingsService.apiKey(for: provider)
    }
}
