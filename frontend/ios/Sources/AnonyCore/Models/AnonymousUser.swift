import Foundation

public struct AnonymousUser: Identifiable, Codable, Sendable {
    public let id: UUID
    public let alias: String
    public let avatarId: String
    public let createdAt: Date

    public init(id: UUID = UUID(), alias: String, avatarId: String, createdAt: Date = Date()) {
        self.id = id
        self.alias = alias
        self.avatarId = avatarId
        self.createdAt = createdAt
    }
}
