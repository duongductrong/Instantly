import SwiftUI

@Observable
final class ExpandedWindowViewModel {
    var queryText: String = ""
    var attachments: [AttachmentItem] = []
    var statusMessage: String = ""
    var isLoading: Bool = false

    struct AttachmentItem: Identifiable {
        let id = UUID()
        let filename: String
        let icon: String
    }
}
