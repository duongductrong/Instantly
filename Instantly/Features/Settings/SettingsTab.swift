import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case about
    case updates
    case assistant
    case model
    case quickActions

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .general: "General"
        case .about: "About"
        case .updates: "Updates"
        case .assistant: "Assistant"
        case .model: "Model"
        case .quickActions: "Quick Actions"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .about: "info.circle"
        case .updates: "arrow.clockwise.circle"
        case .assistant: "sparkles"
        case .model: "cpu"
        case .quickActions: "bolt.badge.clock"
        }
    }

    /// Tabs that appear before the section header
    static let topSection: [SettingsTab] = [.general, .about, .updates]

    /// Tabs that appear under the "Instantly" section header
    static let instantlySection: [SettingsTab] = [.assistant, .model, .quickActions]
}
