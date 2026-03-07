import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: Role
    var content: String
    let timestamp: Date
    /// Optional snippet of selected text attached when the message was sent.
    var attachedSelectedText: String?

    enum Role: String, Codable {
        case system
        case user
        case assistant
    }

    init(role: Role, content: String, attachedSelectedText: String? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.attachedSelectedText = attachedSelectedText
    }
}
