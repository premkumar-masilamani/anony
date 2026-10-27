import Foundation

/// Data transfer object returned by the backend client profile endpoints.
public struct ClientProfileResponse: Codable, Sendable, Identifiable, Equatable {
    public var id: UUID { clientId }
    public let clientId: UUID
    public let userId: UUID
    public let email: String
    public let firstName: String
    public let lastName: String
    public let alias: String
    public let isAnonymous: Bool
    public let isOnboarded: Bool
    public let createdAt: Date

    public init(
        clientId: UUID,
        userId: UUID,
        email: String,
        firstName: String,
        lastName: String,
        alias: String,
        isAnonymous: Bool,
        isOnboarded: Bool,
        createdAt: Date = Date()
    ) {
        self.clientId = clientId
        self.userId = userId
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.alias = alias
        self.isAnonymous = isAnonymous
        self.isOnboarded = isOnboarded
        self.createdAt = createdAt
    }
}
