import SwiftUI

@Observable
final class ExpandedWindowViewModel {
    var queryText: String = ""
    var attachments: [AttachmentItem] = []
    var statusMessage: String = ""
    var isLoading: Bool = false
    var contextItems: [ContextItem] = []

    struct AttachmentItem: Identifiable {
        let id = UUID()
        let filename: String
        let icon: String
    }

    // MARK: - Context Management

    func setContext(_ items: [ContextItem]) {
        contextItems = items
    }

    func removeContextItem(_ item: ContextItem) {
        contextItems.removeAll { $0.id == item.id }
    }

    func clearContext() {
        contextItems.removeAll()
    }
}
