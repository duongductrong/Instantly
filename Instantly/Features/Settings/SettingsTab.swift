import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case about
    case assistant
    case model

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .general: "General"
        case .about: "About"
        case .assistant: "Assistant"
        case .model: "Model"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .about: "info.circle"
        case .assistant: "sparkles"
        case .model: "cpu"
        }
    }

    /// Tabs that appear before the section header
    static let topSection: [SettingsTab] = [.general, .about]

    /// Tabs that appear under the "Instantly" section header
    static let instantlySection: [SettingsTab] = [.assistant, .model]
}
