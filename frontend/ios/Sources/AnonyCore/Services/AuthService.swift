import Foundation

public protocol AuthServiceProtocol: Sendable {
    func register(email: String, password: String) async throws -> AuthSession
}

public final class MockAuthService: AuthServiceProtocol, Sendable {
    private let identityService: IdentityService

    public init(identityService: IdentityService = .shared) {
        self.identityService = identityService
    }

    public func register(email: String, password: String) async throws -> AuthSession {
        // Validate email
        guard RegistrationValidator.isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        // Validate password strictly: length > 8 and <= 32
        if password.count <= 8 {
            throw AuthError.passwordTooShort
        }
        if password.count > 32 {
            throw AuthError.passwordTooLong
        }

        // Mock API network latency / DB save
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s

        // Generate deterministic/procedural tranquil alias & avatar ID based on email
        let seed = abs(email.hashValue) % 1000
        let tranquilPrefixes = ["Tranquil", "Serene", "Calm", "Gentle", "Peaceful", "Silent", "Quiet"]
        let tranquilNouns = ["River", "Pine", "Willow", "Breeze", "Creek", "Stone", "Meadow"]
        let alias = "\(tranquilPrefixes[seed % tranquilPrefixes.count])\(tranquilNouns[(seed / 7) % tranquilNouns.count])\(seed % 100)"
        let avatarId = "avatar-\(UUID().uuidString.prefix(8))"
        let token = "jwt_mock_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"

        let session = AuthSession(
            token: token,
            alias: alias,
            avatarId: avatarId,
            email: email
        )

        // Save session credentials in Keychain
        _ = identityService.saveSession(token: session.token, alias: session.alias, email: session.email)

        return session
    }
}
