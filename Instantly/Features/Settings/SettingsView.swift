import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            Color.black.opacity(0.62)

            NavigationSplitView {
                SettingsSidebarView(selectedSection: selectedSectionBinding)
            } detail: {
                selectedSectionContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .navigationSplitViewStyle(.balanced)
            .toolbar(.hidden, for: .windowToolbar)
            .ignoresSafeArea(.container, edges: .top)
        }
        .preferredColorScheme(.dark)
        .alert("Reset all settings?", isPresented: $viewModel.showResetAllConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetAllSettings()
            }
        } message: {
            Text("This will clear settings and provider API keys.")
        }
    }

    private var selectedSectionBinding: Binding<SettingsViewModel.Section?> {
        Binding(
            get: { viewModel.selectedSection },
            set: { newValue in
                if let newValue {
                    viewModel.selectedSection = newValue
                }
            }
        )
    }

    @ViewBuilder
    private var selectedSectionContent: some View {
        switch viewModel.selectedSection {
        case .assistant:
            AssistantSettingsSectionView(
                settings: viewModel.settings.assistant,
                onSystemPromptChanged: viewModel.updateAssistantSystemPrompt,
                onIncludeActiveAppContextChanged: viewModel.updateIncludeActiveAppContext,
                onIncludeSelectedTextContextChanged: viewModel.updateIncludeSelectedTextContext,
                onShortcutChanged: viewModel.updateNewChatShortcut,
                onReset: viewModel.resetAssistant
            )
        case .model:
            ModelSettingsSectionView(
                settings: viewModel.settings.model,
                openAIAPIKey: Binding(
                    get: { viewModel.openAIAPIKey },
                    set: viewModel.updateOpenAIAPIKey
                ),
                claudeAPIKey: Binding(
                    get: { viewModel.claudeAPIKey },
                    set: viewModel.updateClaudeAPIKey
                ),
                customAPIKey: Binding(
                    get: { viewModel.customAPIKey },
                    set: viewModel.updateCustomAPIKey
                ),
                validationMessage: viewModel.modelValidationMessage,
                keychainMessage: viewModel.keychainStatusMessage,
                onProviderChanged: viewModel.updateSelectedProvider,
                onOllamaBaseURLChanged: viewModel.updateOllamaBaseURL,
                onOllamaModelChanged: viewModel.updateOllamaModel,
                onOpenAIBaseURLChanged: viewModel.updateOpenAIBaseURL,
                onOpenAIModelChanged: viewModel.updateOpenAIModel,
                onClaudeModelChanged: viewModel.updateClaudeModel,
                onCustomProviderLabelChanged: viewModel.updateCustomProviderLabel,
                onCustomBaseURLChanged: viewModel.updateCustomBaseURL,
                onCustomModelChanged: viewModel.updateCustomModel,
                onTemperatureChanged: viewModel.updateTemperature,
                onMaxTokensChanged: viewModel.updateMaxTokens
            )
        case .system:
            SystemSettingsSectionView(
                settings: viewModel.settings.system,
                statusMessage: viewModel.systemStatusMessage,
                keychainMessage: viewModel.keychainStatusMessage,
                onLaunchAtLoginChanged: viewModel.updateLaunchAtLogin,
                onGlobalHotkeyChanged: viewModel.updateGlobalHotkey,
                onShowPanelOnAppLaunchChanged: viewModel.updateShowPanelOnAppLaunch,
                onResetAll: {
                    viewModel.showResetAllConfirmation = true
                }
            )
        }
    }
}
