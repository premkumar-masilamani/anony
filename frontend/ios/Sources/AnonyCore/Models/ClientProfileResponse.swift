import Foundation

/// Data transfer object returned by the backend client profile endpoints (/api/v1/clients/me).
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
    public let isAnonymousMode: Bool
    public let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case clientId
        case userId
        case email
        case firstName
        case lastName
        case alias
        case isAnonymous
        case isOnboarded
        case isAnonymousMode
        case createdAt
    }

    public init(
        clientId: UUID,
        userId: UUID,
        email: String,
        firstName: String,
        lastName: String,
        alias: String,
        isAnonymous: Bool,
        isOnboarded: Bool,
        isAnonymousMode: Bool = true,
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
        self.isAnonymousMode = isAnonymousMode
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientId = try container.decode(UUID.self, forKey: .clientId)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.email = try container.decode(String.self, forKey: .email)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.alias = try container.decode(String.self, forKey: .alias)
        self.isAnonymous = try container.decode(Bool.self, forKey: .isAnonymous)
        self.isOnboarded = try container.decode(Bool.self, forKey: .isOnboarded)
        self.isAnonymousMode = try container.decodeIfPresent(Bool.self, forKey: .isAnonymousMode) ?? self.isAnonymous
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
