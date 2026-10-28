import Foundation

public protocol AuthServiceProtocol: Sendable {
    func register(email: String, password: String) async throws -> AuthSession
    func registerCoach(payload: CoachRegistrationPayload) async throws -> AuthSession
    func login(email: String, password: String) async throws -> AuthSession
    func logout() async throws
    func fetchCoachProfile() async throws -> CoachProfileResponse
    func updateCoachProfile(payload: CoachUpdatePayload) async throws -> CoachProfileResponse
    func fetchClientProfile() async throws -> ClientProfileResponse
    func updateClientPrivacyMode(isAnonymousMode: Bool) async throws -> ClientProfileResponse
    func fetchCoachAvailabilities(coachId: UUID, from: Date?, to: Date?) async throws -> [CoachAvailabilitySlotResponse]
}

extension AuthServiceProtocol {
    public func updateClientPrivacyMode(isAnonymousMode: Bool) async throws -> ClientProfileResponse {
        return ClientProfileResponse(
            clientId: UUID(),
            userId: UUID(),
            email: "client@anony.internal",
            firstName: "Anonymous",
            lastName: "Client",
            alias: "TranquilOwl42",
            isAnonymous: isAnonymousMode,
            isOnboarded: true,
            isAnonymousMode: isAnonymousMode
        )
    }

    public func fetchCoachAvailabilities(coachId: UUID, from: Date?, to: Date?) async throws -> [CoachAvailabilitySlotResponse] {
        return []
    }
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

            let alias = identityService.fetchAlias() ?? ClientProfile.generateTranquilAlias()
            let avatarId = alias

            let authSession = AuthSession(
                token: loginPayload.token,
                alias: alias,
                avatarId: avatarId,
                email: loginPayload.user.email,
                role: loginPayload.user.role
            )

            _ = identityService.saveSession(
                token: authSession.token,
                alias: authSession.alias,
                email: authSession.email,
                role: authSession.role
            )
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
            request.httpBody = Data()

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

        let generatedAlias = ClientProfile.generateTranquilAlias()
        let requestBody = ["email": email, "password": password, "alias": generatedAlias]
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

            let alias = generatedAlias
            let avatarId = alias

            let authSession = AuthSession(
                token: loginPayload.token,
                alias: alias,
                avatarId: avatarId,
                email: loginPayload.user.email,
                role: loginPayload.user.role
            )

            _ = identityService.saveSession(
                token: authSession.token,
                alias: authSession.alias,
                email: authSession.email,
                role: authSession.role
            )
            return authSession
        } else if httpResponse.statusCode == 404 {
            throw AuthError.registrationFailed("Registration endpoint is not available on this server. Please use Sign In.")
        } else {
            let serverError = parseErrorMessage(from: data) ?? "Registration request failed with status code \(httpResponse.statusCode)."
            throw AuthError.registrationFailed(serverError)
        }
    }

    public func registerCoach(payload: CoachRegistrationPayload) async throws -> AuthSession {
        guard RegistrationValidator.isValidEmail(payload.email) else {
            throw AuthError.invalidEmail
        }

        if payload.password.count <= 8 {
            throw AuthError.passwordTooShort
        }
        if payload.password.count > 32 {
            throw AuthError.passwordTooLong
        }

        let registerCoachURL = APIEndpoints.url(for: APIEndpoints.register, baseURL: baseURL)
        var request = URLRequest(url: registerCoachURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(payload)
        } catch {
            throw AuthError.registrationFailed("Failed to encode coach registration payload.")
        }

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
            if let loginPayload = try? decoder.decode(RemoteLoginResponse.self, from: data) {
                let alias = identityService.fetchAlias() ?? ClientProfile.generateTranquilAlias()
                let authSession = AuthSession(
                    token: loginPayload.token,
                    alias: alias,
                    avatarId: alias,
                    email: loginPayload.user.email,
                    role: loginPayload.user.role
                )
                _ = identityService.saveSession(
                    token: authSession.token,
                    alias: authSession.alias,
                    email: authSession.email,
                    role: authSession.role
                )
                return authSession
            }
            return try await login(email: payload.email, password: payload.password)
        } else {
            let serverError = parseErrorMessage(from: data) ?? "Coach registration failed with status code \(httpResponse.statusCode)."
            throw AuthError.registrationFailed(serverError)
        }
    }

    public func fetchCoachProfile() async throws -> CoachProfileResponse {
        guard let token = identityService.fetchToken(), !token.isEmpty else {
            throw AuthError.unauthorized
        }

        let profileURL = APIEndpoints.url(for: APIEndpoints.coachesMe, baseURL: baseURL)
        var request = URLRequest(url: profileURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

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
            decoder.dateDecodingStrategy = .iso8601
            guard let profile = try? decoder.decode(CoachProfileResponse.self, from: data) else {
                throw AuthError.registrationFailed("Failed to parse coach profile.")
            }
            return profile
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthError.unauthorized
        } else {
            let serverError = parseErrorMessage(from: data) ?? "Failed to fetch coach profile with status code \(httpResponse.statusCode)."
            throw AuthError.registrationFailed(serverError)
        }
    }

    public func updateCoachProfile(payload: CoachUpdatePayload) async throws -> CoachProfileResponse {
        guard let token = identityService.fetchToken(), !token.isEmpty else {
            throw AuthError.unauthorized
        }

        let profileURL = APIEndpoints.url(for: APIEndpoints.coachesMe, baseURL: baseURL)
        var request = URLRequest(url: profileURL)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(payload)
        } catch {
            throw AuthError.registrationFailed("Failed to encode coach update payload.")
        }

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
            decoder.dateDecodingStrategy = .iso8601
            guard let profile = try? decoder.decode(CoachProfileResponse.self, from: data) else {
                throw AuthError.registrationFailed("Failed to parse updated coach profile.")
            }
            return profile
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthError.unauthorized
        } else {
            let serverError = parseErrorMessage(from: data) ?? "Failed to update coach profile with status code \(httpResponse.statusCode)."
            throw AuthError.registrationFailed(serverError)
        }
    }

    public func fetchClientProfile() async throws -> ClientProfileResponse {
        guard let token = identityService.fetchToken(), !token.isEmpty else {
            throw AuthError.unauthorized
        }

        let profileURL = APIEndpoints.url(for: APIEndpoints.clientsMe, baseURL: baseURL)
        var request = URLRequest(url: profileURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

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
            decoder.dateDecodingStrategy = .iso8601
            guard let profile = try? decoder.decode(ClientProfileResponse.self, from: data) else {
                throw AuthError.registrationFailed("Failed to parse client profile.")
            }
            return profile
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthError.unauthorized
        } else {
            let serverError = parseErrorMessage(from: data) ?? "Failed to fetch client profile with status code \(httpResponse.statusCode)."
            throw AuthError.registrationFailed(serverError)
        }
    }

    public func updateClientPrivacyMode(isAnonymousMode: Bool) async throws -> ClientProfileResponse {
        guard let token = identityService.fetchToken(), !token.isEmpty else {
            throw AuthError.unauthorized
        }

        let profileURL = APIEndpoints.url(for: APIEndpoints.clientsMe, baseURL: baseURL)
        var request = URLRequest(url: profileURL)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["is_anonymous_mode": isAnonymousMode])

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
            decoder.dateDecodingStrategy = .iso8601
            guard let profile = try? decoder.decode(ClientProfileResponse.self, from: data) else {
                throw AuthError.registrationFailed("Failed to parse updated client profile.")
            }
            return profile
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthError.unauthorized
        } else {
            let serverError = parseErrorMessage(from: data) ?? "Failed to update client privacy mode with status code \(httpResponse.statusCode)."
            throw AuthError.registrationFailed(serverError)
        }
    }

    public func fetchCoachAvailabilities(coachId: UUID, from: Date? = nil, to: Date? = nil) async throws -> [CoachAvailabilitySlotResponse] {
        let baseEndpointURL = APIEndpoints.url(for: APIEndpoints.coachAvailabilities(id: coachId), baseURL: baseURL)
        var components = URLComponents(url: baseEndpointURL, resolvingAgainstBaseURL: true)

        let isoFormatter = ISO8601DateFormatter()
        var queryItems: [URLQueryItem] = []
        if let fromDate = from {
            queryItems.append(URLQueryItem(name: "from", value: isoFormatter.string(from: fromDate)))
        }
        if let toDate = to {
            queryItems.append(URLQueryItem(name: "to", value: isoFormatter.string(from: toDate)))
        }
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        let requestURL = components?.url ?? baseEndpointURL
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = identityService.fetchToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

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
            decoder.dateDecodingStrategy = .iso8601
            guard let slots = try? decoder.decode([CoachAvailabilitySlotResponse].self, from: data) else {
                throw AuthError.registrationFailed("Failed to parse coach availability slots.")
            }
            return slots
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthError.unauthorized
        } else {
            let serverError = parseErrorMessage(from: data) ?? "Failed to fetch coach availability slots with status code \(httpResponse.statusCode)."
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
