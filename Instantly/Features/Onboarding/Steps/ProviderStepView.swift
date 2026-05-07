import SwiftUI

/// Provider selection step — elegant card-based provider picker with native macOS forms.
struct ProviderStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showAPIKey = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignTokens.brandGreen.opacity(0.10))
                        .frame(width: 36, height: 36)
                    Image(systemName: "cpu")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DesignTokens.brandGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Choose Your Provider")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Select and configure your preferred AI provider.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 16) {
                    // Provider chips
                    providerChips

                    // Configuration card
                    configCard
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.2), value: viewModel.selectedProvider)
    }

    // MARK: - Provider Chips

    private var providerChips: some View {
        HStack(spacing: 8) {
            ForEach(ProviderKind.allCases) { provider in
                ProviderOnboardingChip(
                    provider: provider,
                    isSelected: viewModel.selectedProvider == provider
                ) {
                    viewModel.selectedProvider = provider
                }
            }
        }
    }

    // MARK: - Config Card

    private var configCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: providerIcon(viewModel.selectedProvider))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("\(viewModel.selectedProvider.title) Configuration")
                    .font(.system(size: 13, weight: .semibold))
            }

            VStack(spacing: 12) {
                switch viewModel.selectedProvider {
                case .ollama:
                    OnboardingTextField(
                        label: "Base URL",
                        placeholder: "http://localhost:11434",
                        text: $viewModel.ollamaBaseURL
                    )
                    OnboardingTextField(
                        label: "Model",
                        placeholder: "llama3.1",
                        text: $viewModel.ollamaModel
                    )

                case .openAI:
                    OnboardingTextField(
                        label: "Base URL",
                        placeholder: "https://api.openai.com/v1",
                        text: $viewModel.openAIBaseURL
                    )
                    OnboardingTextField(
                        label: "Model",
                        placeholder: "gpt-4.1-mini",
                        text: $viewModel.openAIModel
                    )
                    apiKeyField(text: $viewModel.openAIAPIKey, placeholder: "sk-...")

                case .claude:
                    OnboardingTextField(
                        label: "Base URL",
                        placeholder: "https://api.anthropic.com/v1",
                        text: $viewModel.claudeBaseURL
                    )
                    OnboardingTextField(
                        label: "Model",
                        placeholder: "claude-3-7-sonnet-latest",
                        text: $viewModel.claudeModel
                    )
                    apiKeyField(text: $viewModel.claudeAPIKey, placeholder: "sk-ant-...")

                case .custom:
                    OnboardingTextField(
                        label: "Provider Name",
                        placeholder: "My Provider",
                        text: $viewModel.customLabel
                    )
                    VStack(alignment: .leading, spacing: 6) {
                        Text("API Format")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Picker("API Format", selection: $viewModel.customFormat) {
                            ForEach(CustomProviderFormat.allCases) { fmt in
                                Text(fmt.title).tag(fmt)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    OnboardingTextField(
                        label: "Base URL",
                        placeholder: customBaseURLPrompt,
                        text: $viewModel.customBaseURL
                    )
                    OnboardingTextField(
                        label: "Model",
                        placeholder: "model-name",
                        text: $viewModel.customModel
                    )
                    apiKeyField(text: $viewModel.customAPIKey, placeholder: "...")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - API Key Field

    private func apiKeyField(text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("API Key")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Group {
                    if showAPIKey {
                        TextField("API Key", text: text, prompt: Text(placeholder))
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("API Key", text: text, prompt: Text(placeholder))
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Button {
                    showAPIKey.toggle()
                } label: {
                    Image(systemName: showAPIKey ? "eye.slash" : "eye")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help(showAPIKey ? "Hide API Key" : "Show API Key")
            }
        }
    }

    // MARK: - Helpers

    private var customBaseURLPrompt: String {
        switch viewModel.customFormat {
        case .openAI:
            "https://api.provider.com/v1"
        case .anthropic:
            "https://api.provider.com/v1"
        }
    }

    private func providerIcon(_ provider: ProviderKind) -> String {
        switch provider {
        case .ollama: "server.rack"
        case .openAI: "brain"
        case .claude: "sparkle"
        case .custom: "wrench.and.screwdriver"
        }
    }
}

// MARK: - Provider Onboarding Chip

private struct ProviderOnboardingChip: View {
    let provider: ProviderKind
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(provider.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
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
            AnyShapeStyle(DesignTokens.brandGreen.opacity(0.10))
        } else if isHovered {
            AnyShapeStyle(Color.primary.opacity(0.04))
        } else {
            AnyShapeStyle(Color.clear)
        }
    }

    private var borderColor: Color {
        if isSelected {
            DesignTokens.brandGreen.opacity(0.40)
        } else if isHovered {
            .primary.opacity(0.14)
        } else {
            .primary.opacity(0.08)
        }
    }
}

// MARK: - Onboarding Text Field

private struct OnboardingTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text, prompt: Text(placeholder))
                .textFieldStyle(.roundedBorder)
        }
    }
}
