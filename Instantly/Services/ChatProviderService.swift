import Foundation

/// Unified chat provider that dispatches streaming requests to the correct backend
/// based on the provider kind (Ollama, OpenAI, Claude, or Custom).
enum ChatProviderService {
    enum ChatError: LocalizedError {
        case unsupportedProvider(ProviderKind)

        var errorDescription: String? {
            switch self {
            case let .unsupportedProvider(provider):
                "Provider \(provider.title) is not yet supported."
            }
        }
    }

    /// Sends a streaming chat request using the given provider configuration.
    static func sendStreamingChat(
        messages: [ChatMessage],
        provider: ProviderKind,
        runtimeConfig: ProviderRuntimeConfig,
        apiKey: String,
        systemPrompt: String
    )
        -> AsyncThrowingStream<String, Error>
    {
        switch runtimeConfig {
        case let .ollama(config):
            OllamaChatService.sendStreamingChat(
                messages: messages,
                config: config,
                systemPrompt: systemPrompt
            )
        case let .openAI(config):
            OpenAIChatService.sendStreamingChat(
                messages: messages,
                config: config,
                apiKey: apiKey,
                systemPrompt: systemPrompt
            )
        case let .claude(config):
            ClaudeChatService.sendStreamingChat(
                messages: messages,
                config: config,
                apiKey: apiKey,
                systemPrompt: systemPrompt,
                maxTokens: 4_096
            )
        case let .custom(config):
            switch config.format {
            case .openAI:
                OpenAIChatService.sendStreamingChat(
                    messages: messages,
                    config: config,
                    apiKey: apiKey,
                    systemPrompt: systemPrompt,
                    temperature: config.temperature,
                    maxTokens: config.maxTokens
                )
            case .anthropic:
                ClaudeChatService.sendStreamingChat(
                    messages: messages,
                    config: ClaudeProviderConfig(baseURL: config.baseURL, model: config.model),
                    apiKey: apiKey,
                    systemPrompt: systemPrompt,
                    maxTokens: config.maxTokens
                )
            }
        }
    }

    /// Convenience overload that reads the API key from SettingsService.
    static func sendStreamingChat(
        messages: [ChatMessage],
        provider: ProviderKind,
        runtimeConfig: ProviderRuntimeConfig,
        systemPrompt: String
    )
        -> AsyncThrowingStream<String, Error>
    {
        let apiKey = SettingsService.shared.apiKey(for: provider)
        return sendStreamingChat(
            messages: messages,
            provider: provider,
            runtimeConfig: runtimeConfig,
            apiKey: apiKey,
            systemPrompt: systemPrompt
        )
    }
}
