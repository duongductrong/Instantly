import SwiftUI

/// Ollama setup step — premium macOS-style wizard page with status dashboard and install guidance.
struct OllamaSetupStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero header
            heroHeader
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 20) {
                    // Status dashboard
                    statusDashboard

                    // Dynamic content based on state
                    dynamicContent
                }
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if viewModel.ollamaStatus == .unknown {
                viewModel.checkOllamaInstallation()
            }
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(DesignTokens.brandGreen.opacity(0.10))
                    .frame(width: 56, height: 56)
                Image(systemName: "server.rack")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(DesignTokens.brandGreen)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Ollama Local AI")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                Text("Run AI models locally on your Mac — private, fast, and always available.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Status Dashboard

    private var statusDashboard: some View {
        HStack(spacing: 12) {
            StatusPill(
                title: "Installation",
                icon: "shippingbox",
                text: installStatusText,
                color: installStatusColor,
                isActive: viewModel.ollamaStatus == .checking
            )

            StatusPill(
                title: "Connection",
                icon: "network",
                text: connectionStatusText,
                color: connectionStatusColor,
                isActive: viewModel.connectionStatus == .checking
            )
        }
    }

    // MARK: - Dynamic Content

    @ViewBuilder
    private var dynamicContent: some View {
        switch viewModel.ollamaStatus {
        case .unknown, .checking:
            checkingStateView

        case .notInstalled:
            installGuideView

        case .installed:
            installedStateView
        }
    }

    // MARK: - Checking State

    private var checkingStateView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("Detecting Ollama installation…")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Install Guide

    private var installGuideView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.brandGreen)
                Text("Install Ollama")
                    .font(.system(size: 15, weight: .semibold))
            }

            Text("Ollama wasn't found on your Mac. Choose one of the following methods to install it.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineSpacing(2)

            // Method 1: Download
            InstallMethodCard(
                icon: "globe",
                iconColor: .blue,
                title: "Download from Website",
                subtitle: "Get the latest version from ollama.ai",
                actionTitle: "Open ollama.ai",
                action: {
                    OllamaDetectionService.openDownloadPage()
                }
            )

            // Method 2: Homebrew
            InstallMethodCard(
                icon: "mug",
                iconColor: .orange,
                title: "Install with Homebrew",
                subtitle: "For terminal-savvy users",
                actionTitle: "Copy Command",
                action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("brew install ollama", forType: .string)
                },
                accessory: {
                    HStack(spacing: 6) {
                        Text("brew install ollama")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Spacer()
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
            )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.primary.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Installed State

    private var installedStateView: some View {
        VStack(spacing: 16) {
            // Connection check
            if viewModel.connectionStatus != .connected {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignTokens.brandGreen)
                        Text("Connect to Ollama")
                            .font(.system(size: 15, weight: .semibold))
                    }

                    Text("Ollama is installed. Let's verify the server is running and accessible.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)

                    Button {
                        viewModel.checkOllamaConnection()
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.connectionStatus == .checking {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Check Connection")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(viewModel.connectionStatus == .checking)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.primary.opacity(0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                )
            }

            // Connection error
            if viewModel.connectionStatus == .disconnected {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ollama is not running")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Start Ollama from Launchpad or run `ollama serve` in Terminal.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                        )
                )
            }

            // Model selector
            if viewModel.connectionStatus == .connected {
                modelSelectorCard
            }
        }
    }

    // MARK: - Model Selector Card

    private var modelSelectorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.brandGreen)
                Text("Select a Model")
                    .font(.system(size: 15, weight: .semibold))
            }

            if viewModel.isLoadingModels {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Fetching available models…")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if viewModel.availableModels.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No models found")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Run **ollama pull llama3.1** in Terminal to download your first model.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose the model you want to use for conversations.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Picker("Model", selection: $viewModel.ollamaModel) {
                        ForEach(viewModel.availableModels) { model in
                            HStack(spacing: 6) {
                                Image(systemName: "cube")
                                    .font(.system(size: 10))
                                Text(model.displayName)
                            }
                            .tag(model.name)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.primary.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Status Helpers

    private var installStatusText: String {
        switch viewModel.ollamaStatus {
        case .unknown: "Checking…"
        case .checking: "Checking…"
        case .installed: "Ready"
        case .notInstalled: "Not found"
        }
    }

    private var installStatusColor: Color {
        switch viewModel.ollamaStatus {
        case .unknown, .checking: .secondary
        case .installed: .green
        case .notInstalled: .red
        }
    }

    private var connectionStatusText: String {
        switch viewModel.connectionStatus {
        case .unknown: "Pending"
        case .checking: "Checking…"
        case .connected: "Online"
        case .disconnected: "Offline"
        }
    }

    private var connectionStatusColor: Color {
        switch viewModel.connectionStatus {
        case .unknown: .secondary
        case .checking: .secondary
        case .connected: .green
        case .disconnected: .orange
        }
    }
}
