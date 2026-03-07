import SwiftUI

/// Completion step — confirms setup with a clean summary.
struct CompletionStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
                .padding(.bottom, 16)

            Text("You're All Set")
                .font(.system(size: 22, weight: .bold))
                .padding(.bottom, 6)

            Text("Instantly is ready to assist you.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)

            // Summary
            GroupBox {
                VStack(spacing: 0) {
                    summaryRow(label: "Provider", value: viewModel.selectedProvider.title, icon: "cpu")
                    Divider().padding(.vertical, 6)
                    summaryRow(label: "Model", value: activeModelName, icon: "brain.head.profile")

                    if viewModel.selectedProvider == .ollama {
                        Divider().padding(.vertical, 6)
                        summaryRow(
                            label: "Ollama",
                            value: viewModel.connectionStatus == .connected ? "Connected" : "Not connected",
                            icon: viewModel.connectionStatus == .connected ? "checkmark.circle" : "xmark.circle"
                        )
                    }
                }
            }
            .frame(maxWidth: 280)

            Spacer()

            Button {
                viewModel.finish()
            } label: {
                Text("Start Using Instantly")
                    .frame(width: 200)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var activeModelName: String {
        let name: String = switch viewModel.selectedProvider {
        case .ollama: viewModel.ollamaModel
        case .openAI: viewModel.openAIModel
        case .claude: viewModel.claudeModel
        case .custom: viewModel.customModel
        }
        return name.isEmpty ? "—" : name
    }

    private func summaryRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
        }
    }
}
