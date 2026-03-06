import Foundation
import Observation

@MainActor
@Observable
final class SettingsService {
    static let shared = SettingsService()

    private(set) var settings: AppSettings
    private(set) var keychainErrorMessage: String = ""

    private let store: UserDefaultsSettingsStore

    private init(store: UserDefaultsSettingsStore = UserDefaultsSettingsStore()) {
        self.store = store

        var loadedSettings = store.load()
        loadedSettings.system.launchAtLogin = LaunchAtLoginService.isEnabled()
        self.settings = loadedSettings

        persist()
    }

    func updateAssistant(_ update: (inout AssistantSettings) -> Void) {
        update(&settings.assistant)
        persist()
    }

    func updateModel(_ update: (inout ModelSettings) -> Void) {
        update(&settings.model)
        persist()
    }

    func updateSystem(_ update: (inout SystemSettings) -> Void) {
        update(&settings.system)
        persist()
    }

    func updateQuickActions(_ update: (inout QuickActionsSettings) -> Void) {
        update(&settings.quickActions)
        persist()
    }

    func resetAssistantToDefaults() {
        settings.assistant = .defaultValue
        persist()
    }

    func resetAllSettings() {
        settings = .defaultValue
        settings.system.launchAtLogin = LaunchAtLoginService.isEnabled()

        for provider in ProviderKind.allCases where provider.requiresAPIKey {
            do {
                if let account = provider.apiKeyAccount {
                    try KeychainService.deleteSecret(account: account)
                }
            } catch {
                keychainErrorMessage = error.localizedDescription
            }
        }

        persist()
    }

    func apiKey(for provider: ProviderKind) -> String {
        guard let account = provider.apiKeyAccount else { return "" }
        do {
            return try KeychainService.getSecret(account: account) ?? ""
        } catch {
            keychainErrorMessage = error.localizedDescription
            return ""
        }
    }

    func setAPIKey(_ value: String, for provider: ProviderKind) {
        guard let account = provider.apiKeyAccount else { return }

        do {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                try KeychainService.deleteSecret(account: account)
            } else {
                try KeychainService.setSecret(trimmed, account: account)
            }
            keychainErrorMessage = ""
        } catch {
            keychainErrorMessage = error.localizedDescription
        }
    }

    func validateCurrentModelConfiguration() -> String? {
        let model = settings.model
        guard model.maxTokens > 0 else { return "Max tokens must be greater than 0." }
        guard model.temperature >= 0, model.temperature <= 2 else {
            return "Temperature must be between 0 and 2."
        }

        switch model.selectedProvider {
        case .ollama:
            guard isValidURL(model.ollama.baseURL) else {
                return "Ollama base URL is invalid."
            }
            guard !model.ollama.model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return "Ollama model is required."
            }
        case .openAI:
            guard isValidURL(model.openAI.baseURL) else {
                return "OpenAI base URL is invalid."
            }
            guard !model.openAI.model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return "OpenAI model is required."
            }
            guard !apiKey(for: .openAI).isEmpty else {
                return "OpenAI API key is required."
            }
        case .claude:
            guard !model.claude.model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return "Claude model is required."
            }
            guard !apiKey(for: .claude).isEmpty else {
                return "Claude API key is required."
            }
        case .custom:
            guard !model.custom.providerLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return "Custom provider label is required."
            }
            guard isValidURL(model.custom.baseURL) else {
                return "Custom provider base URL is invalid."
            }
            guard !model.custom.model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return "Custom provider model is required."
            }
            guard !apiKey(for: .custom).isEmpty else {
                return "Custom provider API key is required."
            }
        }

        return nil
    }

    private func persist() {
        settings.schemaVersion = AppSettings.currentSchemaVersion
        store.save(settings)
    }

    private func isValidURL(_ text: String) -> Bool {
        guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return false
        }
        return url.scheme != nil && url.host != nil
    }
}
