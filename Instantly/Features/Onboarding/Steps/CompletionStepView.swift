import SwiftUI

/// Completion step — elegant confirmation with animated checkmark and summary.
struct CompletionStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showCheckmark = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Subtle ambient gradient
            RadialGradient(
                colors: [
                    DesignTokens.brandGreen.opacity(0.06),
                    Color.clear,
                ],
                center: .top,
                startRadius: 80,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(DesignTokens.brandGreen.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignTokens.brandGreen)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1.0 : 0.0)
                }
                .padding(.bottom, 24)

                // Title
                Text("You're All Set")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.bottom, 6)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 8)

                // Subtitle
                Text("Instantly is ready to assist you.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 28)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 8)

                // Summary card
                summaryCard
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 12)

                Spacer()

                // Shortcut hint
                HStack(spacing: 6) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Text("Press")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                    Text("⌘ + ,")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("anytime to open settings")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 16)
                .opacity(showContent ? 1.0 : 0.0)

                // Start button
                Button {
                    viewModel.finish()
                } label: {
                    Text("Start Using Instantly")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 240)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
                .padding(.bottom, 48)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.snappy(duration: 0.4)) {
                showCheckmark = true
            }
            withAnimation(.snappy(duration: 0.4).delay(0.15)) {
                showContent = true
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 0) {
            summaryRow(label: "Provider", value: viewModel.selectedProvider.title, icon: "cpu")
            Divider().padding(.vertical, 8)
            summaryRow(label: "Model", value: activeModelName, icon: "brain.head.profile")

            if viewModel.selectedProvider == .ollama {
                Divider().padding(.vertical, 8)
                summaryRow(
                    label: "Ollama",
                    value: viewModel.connectionStatus == .connected ? "Connected" : "Not connected",
                    icon: viewModel.connectionStatus == .connected ? "checkmark.circle" : "xmark.circle",
                    iconColor: viewModel.connectionStatus == .connected ? .green : .orange
                )
            }
        }
        .padding(16)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func summaryRow(label: String, value: String, icon: String, iconColor: Color? = nil) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(iconColor ?? .secondary)
                .frame(width: 18)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
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
}
