import AppKit
import Carbon.HIToolbox
import Foundation
import SwiftUI

struct AppSettings: Codable, Equatable {
    static let currentSchemaVersion = 1
    static let defaultTemperature = 0.7
    static let defaultMaxTokens = 2_048

    var schemaVersion: Int
    var assistant: AssistantSettings
    var model: ModelSettings
    var system: SystemSettings
    var quickActions: QuickActionsSettings

    init(
        schemaVersion: Int = AppSettings.currentSchemaVersion,
        assistant: AssistantSettings,
        model: ModelSettings,
        system: SystemSettings,
        quickActions: QuickActionsSettings = .defaultValue
    ) {
        self.schemaVersion = schemaVersion
        self.assistant = assistant
        self.model = model
        self.system = system
        self.quickActions = quickActions
    }

    static let defaultValue = AppSettings(
        assistant: .defaultValue,
        model: .defaultValue,
        system: .defaultValue,
        quickActions: .defaultValue
    )
}

struct AssistantSettings: Codable, Equatable {
    var systemPrompt: String
    var includeActiveAppContext: Bool
    var includeSelectedTextContext: Bool
    var newChatShortcut: HotkeyBinding

    static let defaultValue = AssistantSettings(
        systemPrompt: "You are a helpful AI assistant called Instantly.",
        includeActiveAppContext: true,
        includeSelectedTextContext: true,
        newChatShortcut: .commandN
    )
}

struct ModelSettings: Codable, Equatable {
    var selectedProvider: ProviderKind
    var ollama: OllamaProviderConfig
    var openAI: OpenAIProviderConfig
    var claude: ClaudeProviderConfig
    var custom: CustomProviderConfig
    var temperature: Double
    var maxTokens: Int

    static let defaultValue = ModelSettings(
        selectedProvider: .ollama,
        ollama: .defaultValue,
        openAI: .defaultValue,
        claude: .defaultValue,
        custom: .defaultValue,
        temperature: AppSettings.defaultTemperature,
        maxTokens: AppSettings.defaultMaxTokens
    )

    var activeProviderModel: String {
        switch selectedProvider {
        case .ollama:
            ollama.model
        case .openAI:
            openAI.model
        case .claude:
            claude.model
        case .custom:
            custom.model
        }
    }

    var ollamaRuntimeConfig: OllamaProviderConfig {
        var config = ollama
        config.temperature = temperature
        config.maxTokens = maxTokens
        return config
    }
}

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case auto
    case light
    case dark

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .auto: "Auto"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var resolvedColorScheme: ColorScheme? {
        switch self {
        case .auto: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var resolvedAppearance: NSAppearance? {
        switch self {
        case .auto: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

struct SystemSettings: Codable, Equatable {
    var launchAtLogin: Bool
    var globalHotkey: HotkeyBinding
    var showPanelOnAppLaunch: Bool
    var appearanceMode: AppearanceMode
    var hasCompletedOnboarding: Bool

    static let defaultValue = SystemSettings(
        launchAtLogin: false,
        globalHotkey: .commandComma,
        showPanelOnAppLaunch: true,
        appearanceMode: .auto,
        hasCompletedOnboarding: false
    )
}

enum ProviderKind: String, Codable, CaseIterable, Identifiable {
    case ollama
    case openAI
    case claude
    case custom

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .ollama:
            "Ollama"
        case .openAI:
            "OpenAI"
        case .claude:
            "Claude"
        case .custom:
            "Custom"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .ollama:
            false
        case .openAI, .claude, .custom:
            true
        }
    }

    var apiKeyAccount: String? {
        switch self {
        case .ollama:
            nil
        case .openAI:
            "provider.openai.api-key"
        case .claude:
            "provider.claude.api-key"
        case .custom:
            "provider.custom.api-key"
        }
    }
}

struct OllamaProviderConfig: Codable, Equatable {
    var baseURL: String
    var model: String
    var temperature: Double
    var maxTokens: Int

    static let defaultValue = OllamaProviderConfig(
        baseURL: "http://localhost:11434",
        model: "llama3.1",
        temperature: AppSettings.defaultTemperature,
        maxTokens: AppSettings.defaultMaxTokens
    )
}

struct OpenAIProviderConfig: Codable, Equatable {
    var baseURL: String
    var model: String

    static let defaultValue = OpenAIProviderConfig(
        baseURL: "https://api.openai.com/v1",
        model: "gpt-4.1-mini"
    )
}

struct ClaudeProviderConfig: Codable, Equatable {
    var model: String

    static let defaultValue = ClaudeProviderConfig(model: "claude-3-7-sonnet-latest")
}

struct CustomProviderConfig: Codable, Equatable {
    var providerLabel: String
    var baseURL: String
    var model: String

    static let defaultValue = CustomProviderConfig(
        providerLabel: "",
        baseURL: "",
        model: ""
    )
}

struct HotkeyBinding: Codable, Equatable, Hashable {
    var keyCode: UInt32
    var carbonModifiers: UInt32

    static let commandComma = HotkeyBinding(
        keyCode: UInt32(kVK_ANSI_Comma),
        carbonModifiers: UInt32(cmdKey)
    )

    static let commandN = HotkeyBinding(
        keyCode: UInt32(kVK_ANSI_N),
        carbonModifiers: UInt32(cmdKey)
    )

    var isValid: Bool {
        carbonModifiers != 0
    }

    var displayString: String {
        "\(Self.modifierSymbols(for: carbonModifiers))\(Self.keyDisplay(for: keyCode))"
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }

    static func eventModifierFlags(from carbonModifiers: UInt32) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if carbonModifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        if carbonModifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        if carbonModifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if carbonModifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        return flags
    }

    static func modifierSymbols(for carbonModifiers: UInt32) -> String {
        var symbols = ""
        if carbonModifiers & UInt32(controlKey) != 0 { symbols += "^" }
        if carbonModifiers & UInt32(optionKey) != 0 { symbols += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { symbols += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { symbols += "⌘" }
        return symbols
    }

    static func keyDisplay(for keyCode: UInt32) -> String {
        if let mapped = keyMap[keyCode] {
            return mapped
        }
        return "Key \(keyCode)"
    }

    private static let keyMap: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_ANSI_Comma): ",", UInt32(kVK_ANSI_Period): ".",
        UInt32(kVK_ANSI_Slash): "/", UInt32(kVK_ANSI_Semicolon): ";",
        UInt32(kVK_ANSI_Quote): "'", UInt32(kVK_ANSI_LeftBracket): "[",
        UInt32(kVK_ANSI_RightBracket): "]", UInt32(kVK_ANSI_Backslash): "\\",
        UInt32(kVK_ANSI_Minus): "-", UInt32(kVK_ANSI_Equal): "=",
        UInt32(kVK_Space): "Space", UInt32(kVK_Return): "Return",
        UInt32(kVK_Delete): "Delete", UInt32(kVK_Escape): "Esc",
    ]
}

// MARK: - Quick Action

struct QuickAction: Codable, Equatable, Identifiable {
    var id: UUID
    var label: String
    var prompt: String
    var icon: String
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        label: String,
        prompt: String,
        icon: String = "bolt.fill",
        isEnabled: Bool = true
    ) {
        self.id = id
        self.label = label
        self.prompt = prompt
        self.icon = icon
        self.isEnabled = isEnabled
    }
}

// MARK: - Mentionable Model

struct MentionableModel: Codable, Equatable, Identifiable {
    var id: UUID
    var label: String
    var provider: ProviderKind
    var modelId: String
    var icon: String
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        label: String,
        provider: ProviderKind,
        modelId: String,
        icon: String = "brain.head.profile",
        isEnabled: Bool = true
    ) {
        self.id = id
        self.label = label
        self.provider = provider
        self.modelId = modelId
        self.icon = icon
        self.isEnabled = isEnabled
    }
}

// MARK: - Quick Actions Settings

struct QuickActionsSettings: Codable, Equatable {
    var quickActions: [QuickAction]
    var mentionableModels: [MentionableModel]

    static let defaultValue = QuickActionsSettings(
        quickActions: [
            QuickAction(label: "Summarize", prompt: "Summarize the following:"),
            QuickAction(label: "Translate", prompt: "Translate the following to English:"),
            QuickAction(label: "Explain", prompt: "Explain the following in simple terms:"),
            QuickAction(label: "Fix Grammar", prompt: "Fix the grammar in the following:"),
        ],
        mentionableModels: [
            MentionableModel(label: "GPT-4.1 Mini", provider: .openAI, modelId: "gpt-4.1-mini"),
            MentionableModel(label: "Claude 3.7 Sonnet", provider: .claude, modelId: "claude-3-7-sonnet-latest"),
            MentionableModel(label: "Llama 3.1", provider: .ollama, modelId: "llama3.1"),
            MentionableModel(label: "Gemini 2.5 Pro", provider: .custom, modelId: "gemini-2.5-pro"),
        ]
    )
}
