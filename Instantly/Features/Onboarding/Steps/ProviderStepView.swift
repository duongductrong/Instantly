import SwiftUI

/// Provider selection step — native macOS form with segmented provider picker.
struct ProviderStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showAPIKey = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Choose Your Provider")
                .font(.system(size: 17, weight: .semibold))
                .padding(.bottom, 4)

            Text("Select and configure your preferred AI provider.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)

            Form {
                // Provider picker
                Section {
                    Picker("Provider", selection: $viewModel.selectedProvider) {
                        ForEach(ProviderKind.allCases) { provider in
                            Label(provider.title, systemImage: providerIcon(provider))
                                .tag(provider)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }

                // Configuration
                Section(configSectionTitle) {
                    switch viewModel.selectedProvider {
                    case .ollama:
                        TextField("Base URL", text: $viewModel.ollamaBaseURL, prompt: Text("http://localhost:11434"))
                        TextField("Model", text: $viewModel.ollamaModel, prompt: Text("llama3.1"))

                    case .openAI:
                        TextField("Base URL", text: $viewModel.openAIBaseURL, prompt: Text("https://api.openai.com/v1"))
                        TextField("Model", text: $viewModel.openAIModel, prompt: Text("gpt-4.1-mini"))
                        apiKeyField(text: $viewModel.openAIAPIKey, placeholder: "sk-...")

                    case .claude:
                        TextField("Model", text: $viewModel.claudeModel, prompt: Text("claude-3-7-sonnet-latest"))
                        apiKeyField(text: $viewModel.claudeAPIKey, placeholder: "sk-ant-...")

                    case .custom:
                        TextField("Provider Name", text: $viewModel.customLabel, prompt: Text("My Provider"))
                        TextField("Base URL", text: $viewModel.customBaseURL, prompt: Text("https://..."))
                        TextField("Model", text: $viewModel.customModel, prompt: Text("model-name"))
                        apiKeyField(text: $viewModel.customAPIKey, placeholder: "...")
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.15), value: viewModel.selectedProvider)
    }

    // MARK: - Helpers

    private var configSectionTitle: String {
        "\(viewModel.selectedProvider.title) Configuration"
    }

    private func providerIcon(_ provider: ProviderKind) -> String {
        switch provider {
        case .ollama: "server.rack"
        case .openAI: "brain"
        case .claude: "sparkle"
        case .custom: "wrench.and.screwdriver"
        }
    }

    private func apiKeyField(text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 6) {
            Group {
                if showAPIKey {
                    TextField("API Key", text: text, prompt: Text(placeholder))
                } else {
                    SecureField("API Key", text: text, prompt: Text(placeholder))
                }
            }

            Button {
                showAPIKey.toggle()
            } label: {
                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help(showAPIKey ? "Hide API Key" : "Show API Key")
        }
    }
}
