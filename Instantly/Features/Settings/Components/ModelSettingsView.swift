import SwiftUI

struct ModelSettingsView: View {
    private let settingsService = SettingsService.shared

    @State private var apiKeyText: String = ""
    @State private var showingAPIKey = false

    private var selectedProvider: ProviderKind {
        settingsService.settings.model.selectedProvider
    }

    var body: some View {
        Form {
            providerSection
            providerConfigSection
            parametersSection
            validationSection
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

    // MARK: - Provider Section

    private var providerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Provider")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    ForEach(ProviderKind.allCases) { provider in
                        ProviderChip(
                            provider: provider,
                            isSelected: selectedProvider == provider
                        ) {
                            settingsService.updateModel { $0.selectedProvider = provider }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Provider Config Section

    private var providerConfigSection: some View {
        Section {
            switch selectedProvider {
            case .ollama:
                ollamaConfig
            case .openAI:
                openAIConfig
            case .claude:
                claudeConfig
            case .custom:
                customConfig
            }

            if selectedProvider.requiresAPIKey {
                apiKeyField(for: selectedProvider)
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: providerIcon(for: selectedProvider))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("\(selectedProvider.title) Configuration")
            }
        }
    }

    // MARK: - Parameters Section

    private var parametersSection: some View {
        Section {
            // Temperature
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Temperature")
                        .font(.system(size: 13))
                    Spacer()
                    Text(String(format: "%.1f", settingsService.settings.model.temperature))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Slider(
                    value: Binding(
                        get: { settingsService.settings.model.temperature },
                        set: { value in settingsService.updateModel { $0.temperature = value } }
                    ),
                    in: 0 ... 2,
                    step: 0.1
                )
                .tint(.accentColor)

                HStack {
                    Text("Precise")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("Creative")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            // Max Tokens
            VStack(alignment: .leading, spacing: 6) {
                Text("Max tokens")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField(
                    "2048",
                    value: Binding(
                        get: { settingsService.settings.model.maxTokens },
                        set: { value in settingsService.updateModel { $0.maxTokens = value } }
                    ), format: .number
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
                .multilineTextAlignment(.trailing)
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Parameters")
            }
        }
    }

    // MARK: - Validation Section

    @ViewBuilder
    private var validationSection: some View {
        if let errorMessage = settingsService.validateCurrentModelConfiguration() {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)

                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Provider Configs

    private var ollamaConfig: some View {
        Group {
            SettingsTextField(
                label: "Base URL",
                placeholder: "http://localhost:11434",
                text: Binding(
                    get: { settingsService.settings.model.ollama.baseURL },
                    set: { value in settingsService.updateModel { $0.ollama.baseURL = value } }
                )
            )

            SettingsTextField(
                label: "Model",
                placeholder: "llama3.1",
                text: Binding(
                    get: { settingsService.settings.model.ollama.model },
                    set: { value in settingsService.updateModel { $0.ollama.model = value } }
                )
            )
        }
    }

    private var openAIConfig: some View {
        Group {
            SettingsTextField(
                label: "Base URL",
                placeholder: "https://api.openai.com/v1",
                text: Binding(
                    get: { settingsService.settings.model.openAI.baseURL },
                    set: { value in settingsService.updateModel { $0.openAI.baseURL = value } }
                )
            )

            SettingsTextField(
                label: "Model",
                placeholder: "gpt-4.1-mini",
                text: Binding(
                    get: { settingsService.settings.model.openAI.model },
                    set: { value in settingsService.updateModel { $0.openAI.model = value } }
                )
            )
        }
    }

    private var claudeConfig: some View {
        SettingsTextField(
            label: "Model",
            placeholder: "claude-3-7-sonnet-latest",
            text: Binding(
                get: { settingsService.settings.model.claude.model },
                set: { value in settingsService.updateModel { $0.claude.model = value } }
            )
        )
    }

    private var customConfig: some View {
        Group {
            SettingsTextField(
                label: "Provider label",
                placeholder: "My Provider",
                text: Binding(
                    get: { settingsService.settings.model.custom.providerLabel },
                    set: { value in settingsService.updateModel { $0.custom.providerLabel = value }
                    }
                )
            )

            SettingsTextField(
                label: "Base URL",
                placeholder: "https://...",
                text: Binding(
                    get: { settingsService.settings.model.custom.baseURL },
                    set: { value in settingsService.updateModel { $0.custom.baseURL = value } }
                )
            )

            SettingsTextField(
                label: "Model",
                placeholder: "model-name",
                text: Binding(
                    get: { settingsService.settings.model.custom.model },
                    set: { value in settingsService.updateModel { $0.custom.model = value } }
                )
            )
        }
    }

    // MARK: - API Key Field

    private func apiKeyField(for provider: ProviderKind) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("API Key")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Group {
                    if showingAPIKey {
                        TextField("sk-...", text: $apiKeyText)
                    } else {
                        SecureField("sk-...", text: $apiKeyText)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .onChange(of: apiKeyText) { _, newValue in
                    settingsService.setAPIKey(newValue, for: provider)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showingAPIKey.toggle()
                    }
                } label: {
                    Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help(showingAPIKey ? "Hide API Key" : "Show API Key")
            }
        }
    }

    // MARK: - Helpers

    private func loadAPIKey() {
        let provider = settingsService.settings.model.selectedProvider
        apiKeyText = settingsService.apiKey(for: provider)
    }

    private func providerIcon(for provider: ProviderKind) -> String {
        switch provider {
        case .ollama: "server.rack"
        case .openAI: "brain"
        case .claude: "sparkle"
        case .custom: "wrench.and.screwdriver"
        }
    }
}

// MARK: - Provider Chip

private struct ProviderChip: View {
    let provider: ProviderKind
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))

                Text(provider.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(borderColor, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var icon: String {
        switch provider {
        case .ollama: "server.rack"
        case .openAI: "brain"
        case .claude: "sparkle"
        case .custom: "wrench.and.screwdriver"
        }
    }

    private var background: some ShapeStyle {
        if isSelected {
            AnyShapeStyle(Color.accentColor.opacity(0.12))
        } else if isHovered {
            AnyShapeStyle(Color.primary.opacity(0.05))
        } else {
            AnyShapeStyle(Color.clear)
        }
    }

    private var borderColor: Color {
        if isSelected {
            .accentColor.opacity(0.4)
        } else if isHovered {
            .primary.opacity(0.12)
        } else {
            .primary.opacity(0.08)
        }
    }
}

// MARK: - Settings Text Field (Reusable)

private struct SettingsTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
