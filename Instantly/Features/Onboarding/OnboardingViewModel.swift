import Foundation
import Observation

/// ViewModel managing the onboarding wizard state.
@MainActor
@Observable
final class OnboardingViewModel {
    // MARK: - Step

    enum Step: Int, CaseIterable {
        case welcome = 0
        case ollamaSetup
        case providerSelection
        case completion
    }

    // MARK: - Ollama Status

    enum OllamaStatus: Equatable {
        case unknown
        case checking
        case installed
        case notInstalled
    }

    enum OllamaConnectionStatus: Equatable {
        case unknown
        case checking
        case connected
        case disconnected
    }

    // MARK: - State

    var currentStep: Step = .welcome
    var ollamaStatus: OllamaStatus = .unknown
    var connectionStatus: OllamaConnectionStatus = .unknown
    var availableModels: [OllamaDetectionService.OllamaModel] = []
    var isLoadingModels = false

    // Draft provider settings (mirrors ModelSettings)
    var selectedProvider: ProviderKind = .ollama
    var ollamaBaseURL: String = OllamaProviderConfig.defaultValue.baseURL
    var ollamaModel: String = OllamaProviderConfig.defaultValue.model
    var openAIBaseURL: String = OpenAIProviderConfig.defaultValue.baseURL
    var openAIModel: String = OpenAIProviderConfig.defaultValue.model
    var openAIAPIKey: String = ""
    var claudeModel: String = ClaudeProviderConfig.defaultValue.model
    var claudeAPIKey: String = ""
    var customLabel: String = ""
    var customBaseURL: String = ""
    var customModel: String = ""
    var customAPIKey: String = ""

    var onComplete: (() -> Void)?

    // MARK: - Computed

    var stepCount: Int {
        Step.allCases.count
    }

    var stepIndex: Int {
        currentStep.rawValue
    }

    var isFirstStep: Bool {
        currentStep == .welcome
    }

    var isLastStep: Bool {
        currentStep == .completion
    }

    var canGoNext: Bool {
        switch currentStep {
        case .welcome:
            true
        case .ollamaSetup:
            true // Can skip Ollama setup
        case .providerSelection:
            true // Basic validation on finish
        case .completion:
            true
        }
    }

    // MARK: - Navigation

    func goNext() {
        guard let nextRaw = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextRaw
    }

    func goBack() {
        guard let prevRaw = Step(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prevRaw
    }

    // MARK: - Ollama Checks

    func checkOllamaInstallation() {
        ollamaStatus = .checking
        // Run on background thread since it uses Process
        Task.detached { [weak self] in
            let installed = OllamaDetectionService.isOllamaInstalled()
            await MainActor.run {
                self?.ollamaStatus = installed ? .installed : .notInstalled
                if installed {
                    self?.checkOllamaConnection()
                }
            }
        }
    }

    func checkOllamaConnection() {
        connectionStatus = .checking
        Task {
            let running = await OllamaDetectionService.isOllamaRunning(baseURL: ollamaBaseURL)
            connectionStatus = running ? .connected : .disconnected
            if running {
                await fetchModels()
            }
        }
    }

    func fetchModels() async {
        isLoadingModels = true
        let models = await OllamaDetectionService.fetchAvailableModels(baseURL: ollamaBaseURL)
        availableModels = models
        isLoadingModels = false

        // Auto-select first model if current isn't in the list
        if !models.isEmpty, !models.contains(where: { $0.name == ollamaModel }) {
            ollamaModel = models[0].name
        }
    }

    // MARK: - Completion

    func finish() {
        let settingsService = SettingsService.shared

        // Save provider configuration
        settingsService.updateModel { model in
            model.selectedProvider = selectedProvider

            switch selectedProvider {
            case .ollama:
                model.ollama.baseURL = ollamaBaseURL
                model.ollama.model = ollamaModel
            case .openAI:
                model.openAI.baseURL = openAIBaseURL
                model.openAI.model = openAIModel
            case .claude:
                model.claude.model = claudeModel
            case .custom:
                model.custom.providerLabel = customLabel
                model.custom.baseURL = customBaseURL
                model.custom.model = customModel
            }
        }

        // Save API keys
        if selectedProvider == .openAI {
            settingsService.setAPIKey(openAIAPIKey, for: .openAI)
        } else if selectedProvider == .claude {
            settingsService.setAPIKey(claudeAPIKey, for: .claude)
        } else if selectedProvider == .custom {
            settingsService.setAPIKey(customAPIKey, for: .custom)
        }

        // Mark onboarding complete
        settingsService.updateSystem { $0.hasCompletedOnboarding = true }

        onComplete?()
    }
}
