import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    enum Section: String, CaseIterable, Identifiable {
        case assistant
        case model
        case system

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .assistant:
                "Assistant"
            case .model:
                "Model"
            case .system:
                "System"
            }
        }

        var subtitle: String {
            switch self {
            case .assistant:
                "Behavior and prompts"
            case .model:
                "Providers and generation"
            case .system:
                "Startup and hotkeys"
            }
        }

        var icon: String {
            switch self {
            case .assistant:
                "sparkles"
            case .model:
                "cpu"
            case .system:
                "gearshape"
            }
        }
    }

    var selectedSection: Section = .assistant
    var settings: AppSettings

    var modelValidationMessage: String = ""
    var systemStatusMessage: String = ""
    var keychainStatusMessage: String = ""
    var showResetAllConfirmation = false

    var openAIAPIKey = ""
    var claudeAPIKey = ""
    var customAPIKey = ""

    private let settingsService: SettingsService

    init(settingsService: SettingsService = .shared) {
        self.settingsService = settingsService
        self.settings = settingsService.settings
        reloadSecrets()
        syncState()
    }

    func updateAssistantSystemPrompt(_ prompt: String) {
        settingsService.updateAssistant { $0.systemPrompt = prompt }
        syncState()
    }

    func updateIncludeActiveAppContext(_ isEnabled: Bool) {
        settingsService.updateAssistant { $0.includeActiveAppContext = isEnabled }
        syncState()
    }

    func updateIncludeSelectedTextContext(_ isEnabled: Bool) {
        settingsService.updateAssistant { $0.includeSelectedTextContext = isEnabled }
        syncState()
    }

    func updateNewChatShortcut(_ shortcut: HotkeyBinding) {
        settingsService.updateAssistant { $0.newChatShortcut = shortcut }
        syncState()
    }

    func resetAssistant() {
        settingsService.resetAssistantToDefaults()
        syncState()
    }

    func updateSelectedProvider(_ provider: ProviderKind) {
        settingsService.updateModel { $0.selectedProvider = provider }
        syncState()
    }

    func updateOllamaBaseURL(_ value: String) {
        settingsService.updateModel { $0.ollama.baseURL = value }
        syncState()
    }

    func updateOllamaModel(_ value: String) {
        settingsService.updateModel { $0.ollama.model = value }
        syncState()
    }

    func updateOpenAIBaseURL(_ value: String) {
        settingsService.updateModel { $0.openAI.baseURL = value }
        syncState()
    }

    func updateOpenAIModel(_ value: String) {
        settingsService.updateModel { $0.openAI.model = value }
        syncState()
    }

    func updateClaudeModel(_ value: String) {
        settingsService.updateModel { $0.claude.model = value }
        syncState()
    }

    func updateCustomProviderLabel(_ value: String) {
        settingsService.updateModel { $0.custom.providerLabel = value }
        syncState()
    }

    func updateCustomBaseURL(_ value: String) {
        settingsService.updateModel { $0.custom.baseURL = value }
        syncState()
    }

    func updateCustomModel(_ value: String) {
        settingsService.updateModel { $0.custom.model = value }
        syncState()
    }

    func updateTemperature(_ value: Double) {
        settingsService.updateModel { $0.temperature = value }
        syncState()
    }

    func updateMaxTokens(_ value: Int) {
        settingsService.updateModel { $0.maxTokens = value }
        syncState()
    }

    func updateOpenAIAPIKey(_ value: String) {
        openAIAPIKey = value
        settingsService.setAPIKey(value, for: .openAI)
        syncState()
    }

    func updateClaudeAPIKey(_ value: String) {
        claudeAPIKey = value
        settingsService.setAPIKey(value, for: .claude)
        syncState()
    }

    func updateCustomAPIKey(_ value: String) {
        customAPIKey = value
        settingsService.setAPIKey(value, for: .custom)
        syncState()
    }

    func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLoginService.setEnabled(enabled)
            settingsService.updateSystem { $0.launchAtLogin = enabled }
            systemStatusMessage = enabled ? "Launch at login enabled." : "Launch at login disabled."
        } catch {
            settingsService.updateSystem { $0.launchAtLogin = LaunchAtLoginService.isEnabled() }
            systemStatusMessage = error.localizedDescription
        }
        syncState()
    }

    func updateGlobalHotkey(_ value: HotkeyBinding) {
        settingsService.updateSystem { $0.globalHotkey = value }
        PanelController.shared.setupHotkey()
        syncState()
    }

    func updateShowPanelOnAppLaunch(_ enabled: Bool) {
        settingsService.updateSystem { $0.showPanelOnAppLaunch = enabled }
        syncState()
    }

    func resetAllSettings() {
        do {
            if LaunchAtLoginService.isEnabled() {
                try LaunchAtLoginService.setEnabled(false)
            }
            settingsService.resetAllSettings()
            systemStatusMessage = "All settings reset to defaults."
        } catch {
            systemStatusMessage = error.localizedDescription
            settingsService.resetAllSettings()
        }

        reloadSecrets()
        PanelController.shared.setupHotkey()
        syncState()
    }

    private func reloadSecrets() {
        openAIAPIKey = settingsService.apiKey(for: .openAI)
        claudeAPIKey = settingsService.apiKey(for: .claude)
        customAPIKey = settingsService.apiKey(for: .custom)
    }

    private func syncState() {
        settings = settingsService.settings
        modelValidationMessage = settingsService.validateCurrentModelConfiguration() ?? ""
        keychainStatusMessage = settingsService.keychainErrorMessage
    }
}
