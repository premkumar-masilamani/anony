import Foundation

public protocol AuthServiceProtocol: Sendable {
    func register(email: String, password: String) async throws -> AuthSession
    func login(email: String, password: String) async throws -> AuthSession
    func logout() async throws
}

/// Data transfer object representing the backend login and registration response payload.
public struct RemoteLoginResponse: Codable, Sendable, Equatable {
    public let token: String
    public let expiresIn: Int64
    public let user: RemoteUserSummary

    public init(token: String, expiresIn: Int64, user: RemoteUserSummary) {
        self.token = token
        self.expiresIn = expiresIn
        self.user = user
    }
}

/// Data transfer object representing user summary returned in the authentication payload.
public struct RemoteUserSummary: Codable, Sendable, Equatable {
    public let userId: UUID
    public let email: String
    public let role: String

    public init(userId: UUID, email: String, role: String) {
        self.userId = userId
        self.email = email
        self.role = role
    }
}

/// Production network implementation of AuthServiceProtocol communicating with the Spring Boot backend.
public final class RemoteAuthService: AuthServiceProtocol, Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let identityService: IdentityService

    public init(
        baseURL: URL = APIConfig.currentBaseURL,
        session: URLSession = .shared,
        identityService: IdentityService = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.identityService = identityService
    }

    public func login(email: String, password: String) async throws -> AuthSession {
        guard RegistrationValidator.isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        if password.count <= 8 {
            throw AuthError.passwordTooShort
        }
        if password.count > 32 {
            throw AuthError.passwordTooLong
        }

        let loginURL = APIEndpoints.url(for: APIEndpoints.login, baseURL: baseURL)
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let requestBody = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AuthError.registrationFailed("Network connection failure: \(error.localizedDescription)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.registrationFailed("Invalid server response.")
        }

        if httpResponse.statusCode == 200 {
            let decoder = JSONDecoder()
            guard let loginPayload = try? decoder.decode(RemoteLoginResponse.self, from: data) else {
                throw AuthError.registrationFailed("Failed to parse authentication response.")
            }

            let seed = abs(email.hashValue) % 1000
            let tranquilPrefixes = ["Tranquil", "Serene", "Calm", "Gentle", "Peaceful", "Silent", "Quiet"]
            let tranquilNouns = ["River", "Pine", "Willow", "Breeze", "Creek", "Stone", "Meadow"]
            let alias = "\(tranquilPrefixes[seed % tranquilPrefixes.count])\(tranquilNouns[(seed / 7) % tranquilNouns.count])\(seed % 100)"
            let avatarId = "avatar-\(loginPayload.user.userId.uuidString.prefix(8).lowercased())"

            let authSession = AuthSession(
                token: loginPayload.token,
                alias: alias,
                avatarId: avatarId,
                email: loginPayload.user.email
            )

            _ = identityService.saveSession(token: authSession.token, alias: authSession.alias, email: authSession.email)
            return authSession
        } else if httpResponse.statusCode == 401 {
            throw AuthError.invalidCredentials
        } else {
            let serverError = parseErrorMessage(from: data) ?? "Authentication request failed with status code \(httpResponse.statusCode)."
            throw AuthError.registrationFailed(serverError)
        }
    }

    public func logout() async throws {
        let activeToken = identityService.fetchToken()

        if let token = activeToken, !token.isEmpty {
            let logoutURL = APIEndpoints.url(for: APIEndpoints.logout, baseURL: baseURL)
            var request = URLRequest(url: logoutURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            do {
                _ = try await session.data(for: request)
            } catch {
                // Network error on logout should not prevent clearing local credentials
            }
        }

        _ = identityService.clearSession()
    }

    public func register(email: String, password: String) async throws -> AuthSession {
        guard RegistrationValidator.isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        if password.count <= 8 {
            throw AuthError.passwordTooShort
        }
        if password.count > 32 {
            throw AuthError.passwordTooLong
        }

        let registerURL = APIEndpoints.url(for: APIEndpoints.register, baseURL: baseURL)
        var request = URLRequest(url: registerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let requestBody = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AuthError.registrationFailed("Network connection failure: \(error.localizedDescription)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.registrationFailed("Invalid server response.")
        }

        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let decoder = JSONDecoder()
            guard let loginPayload = try? decoder.decode(RemoteLoginResponse.self, from: data) else {
                throw AuthError.registrationFailed("Failed to parse registration response.")
            }

            let seed = abs(email.hashValue) % 1000
            let tranquilPrefixes = ["Tranquil", "Serene", "Calm", "Gentle", "Peaceful", "Silent", "Quiet"]
            let tranquilNouns = ["River", "Pine", "Willow", "Breeze", "Creek", "Stone", "Meadow"]
            let alias = "\(tranquilPrefixes[seed % tranquilPrefixes.count])\(tranquilNouns[(seed / 7) % tranquilNouns.count])\(seed % 100)"
            let avatarId = "avatar-\(loginPayload.user.userId.uuidString.prefix(8).lowercased())"

            let authSession = AuthSession(
                token: loginPayload.token,
                alias: alias,
                avatarId: avatarId,
                email: loginPayload.user.email
            )

            _ = identityService.saveSession(token: authSession.token, alias: authSession.alias, email: authSession.email)
            return authSession
        } else if httpResponse.statusCode == 404 {
            throw AuthError.registrationFailed("Registration endpoint is not available on this server. Please use Sign In.")
        } else {
            let serverError = parseErrorMessage(from: data) ?? "Registration request failed with status code \(httpResponse.statusCode)."
            throw AuthError.registrationFailed(serverError)
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let error = json["error"] as? String {
                return error
            }
            if let message = json["message"] as? String {
                return message
            }
        }
        return nil
    }
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

    public func login(email: String, password: String) async throws -> AuthSession {
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

        if password == "WrongPassword#2026" || email == "unregistered@example.com" {
            throw AuthError.invalidCredentials
        }

        // Mock API network latency
        try await Task.sleep(nanoseconds: 200_000_000)

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

        _ = identityService.saveSession(token: session.token, alias: session.alias, email: session.email)
        return session
    }

    public func logout() async throws {
        _ = identityService.clearSession()
    }
}
