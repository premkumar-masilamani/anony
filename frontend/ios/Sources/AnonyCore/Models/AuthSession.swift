import Foundation

public struct AuthSession: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let token: String
    public let alias: String
    public let avatarId: String
    public let email: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        token: String,
        alias: String,
        avatarId: String,
        email: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.token = token
        self.alias = alias
        self.avatarId = avatarId
        self.email = email
        self.createdAt = createdAt
    }
}

public enum AuthError: LocalizedError, Sendable, Equatable {
    case invalidEmail
    case passwordTooShort
    case passwordTooLong
    case registrationFailed(String)
    case keychainPersistenceFailed

    public var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please provide a valid email address."
        case .passwordTooShort:
            return "Password must be longer than 8 characters."
        case .passwordTooLong:
            return "Password cannot exceed 32 characters."
        case .registrationFailed(let reason):
            return "Registration could not be completed: \(reason)"
        case .keychainPersistenceFailed:
            return "Failed to save secure session credentials."
        }
    }
}
