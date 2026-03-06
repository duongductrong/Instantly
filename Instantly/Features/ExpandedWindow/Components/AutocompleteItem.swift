import Foundation

// MARK: - Autocomplete Data Model

enum AutocompleteCategory: String, CaseIterable {
    case model
    case quickAction

    var displayLabel: String {
        switch self {
        case .model: "Model"
        case .quickAction: "Action"
        }
    }

    /// SF Symbol name for items in this category
    var defaultIcon: String {
        switch self {
        case .model: "brain.head.profile"
        case .quickAction: "bolt.fill"
        }
    }
}

struct AutocompleteItem: Identifiable, Equatable {
    let id: UUID
    let label: String
    let category: AutocompleteCategory
    var icon: String

    init(id: UUID = UUID(), label: String, category: AutocompleteCategory, icon: String? = nil) {
        self.id = id
        self.label = label
        self.category = category
        self.icon = icon ?? category.defaultIcon
    }

    /// Checks if this item matches a search query (case-insensitive)
    func matches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return label.localizedCaseInsensitiveContains(query)
    }
}

// MARK: - Build from Settings

extension AutocompleteItem {
    /// Builds autocomplete items from persisted QuickActionsSettings,
    /// including only entries that are enabled.
    static func buildItems(from settings: QuickActionsSettings) -> [AutocompleteItem] {
        let models: [AutocompleteItem] = settings.mentionableModels
            .filter(\.isEnabled)
            .map { model in
                AutocompleteItem(
                    id: model.id,
                    label: model.label,
                    category: .model,
                    icon: model.icon
                )
            }

        let actions: [AutocompleteItem] = settings.quickActions
            .filter(\.isEnabled)
            .map { action in
                AutocompleteItem(
                    id: action.id,
                    label: action.label,
                    category: .quickAction,
                    icon: action.icon
                )
            }

        return models + actions
    }
}

// MARK: - Fake Data for Preview

extension AutocompleteItem {
    static let fakeItems: [AutocompleteItem] = [
        // Models
        AutocompleteItem(label: "GPT-4.1 Mini", category: .model),
        AutocompleteItem(label: "Claude 3.7 Sonnet", category: .model),
        AutocompleteItem(label: "Llama 3.1", category: .model),
        AutocompleteItem(label: "Gemini 2.5 Pro", category: .model),

        // Quick Actions
        AutocompleteItem(label: "Summarize", category: .quickAction),
        AutocompleteItem(label: "Translate", category: .quickAction),
        AutocompleteItem(label: "Explain", category: .quickAction),
        AutocompleteItem(label: "Fix Grammar", category: .quickAction),
    ]
}
