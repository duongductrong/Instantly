import SwiftUI

/// Ollama setup step — detects installation, connection, and available models.
struct OllamaSetupStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Label {
                Text("Ollama Local AI")
                    .font(.system(size: 17, weight: .semibold))
            } icon: {
                Image(systemName: "server.rack")
                    .foregroundStyle(.tint)
            }
            .padding(.bottom, 4)

            Text("Run AI models locally on your Mac for privacy and speed.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)

            // Status rows
            Form {
                Section {
                    LabeledContent {
                        statusBadge(
                            text: installStatusText,
                            style: installBadgeStyle
                        )
                    } label: {
                        Label("Installation", systemImage: "shippingbox")
                    }

                    LabeledContent {
                        statusBadge(
                            text: connectionStatusText,
                            style: connectionBadgeStyle
                        )
                    } label: {
                        Label("Connection", systemImage: "network")
                    }
                }

                // Install guidance
                if viewModel.ollamaStatus == .notInstalled || viewModel.ollamaStatus == .unknown {
                    Section("Install Ollama") {
                        HStack {
                            Text("Download from ollama.ai")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Download") {
                                OllamaDetectionService.openDownloadPage()
                            }
                            .controlSize(.small)
                        }

                        HStack(spacing: 6) {
                            Text("brew install ollama")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                            Spacer()
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString("brew install ollama", forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 10))
                            }
                            .buttonStyle(.borderless)
                            .help("Copy to clipboard")
                        }
                    }
                }

                // Check connection
                Section {
                    Button {
                        viewModel.checkOllamaConnection()
                    } label: {
                        HStack(spacing: 6) {
                            if viewModel.connectionStatus == .checking {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text("Check Connection")
                        }
                    }
                    .disabled(viewModel.connectionStatus == .checking)
                }

                // Model selector
                if viewModel.connectionStatus == .connected {
                    Section("Model") {
                        if viewModel.isLoadingModels {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Loading models…")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        } else if viewModel.availableModels.isEmpty {
                            Label {
                                Text("No models found. Run: **ollama pull llama3.1**")
                                    .font(.system(size: 12))
                            } icon: {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                            }
                        } else {
                            Picker("Model", selection: $viewModel.ollamaModel) {
                                ForEach(viewModel.availableModels) { model in
                                    Text(model.displayName)
                                        .tag(model.name)
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if viewModel.ollamaStatus == .unknown {
                viewModel.checkOllamaInstallation()
            }
        }
    }

    // MARK: - Status Badge

    private enum BadgeStyle {
        case neutral, success, warning, error
    }

    private func statusBadge(text: String, style: BadgeStyle) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(badgeForeground(style))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeBackground(style))
            .clipShape(Capsule())
    }

    private func badgeForeground(_ style: BadgeStyle) -> Color {
        switch style {
        case .neutral: .secondary
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }

    private func badgeBackground(_ style: BadgeStyle) -> Color {
        switch style {
        case .neutral: Color.primary.opacity(0.06)
        case .success: Color.green.opacity(0.12)
        case .warning: Color.orange.opacity(0.12)
        case .error: Color.red.opacity(0.12)
        }
    }

    // MARK: - Status Helpers

    private var installStatusText: String {
        switch viewModel.ollamaStatus {
        case .unknown: "Not checked"
        case .checking: "Checking…"
        case .installed: "Installed"
        case .notInstalled: "Not found"
        }
    }

    private var installBadgeStyle: BadgeStyle {
        switch viewModel.ollamaStatus {
        case .unknown, .checking: .neutral
        case .installed: .success
        case .notInstalled: .error
        }
    }

    private var connectionStatusText: String {
        switch viewModel.connectionStatus {
        case .unknown: "Not checked"
        case .checking: "Connecting…"
        case .connected: "Connected"
        case .disconnected: "Not running"
        }
    }

    private var connectionBadgeStyle: BadgeStyle {
        switch viewModel.connectionStatus {
        case .unknown, .checking: .neutral
        case .connected: .success
        case .disconnected: .warning
        }
    }
}
