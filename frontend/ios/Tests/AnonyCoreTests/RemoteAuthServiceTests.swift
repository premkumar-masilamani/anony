import Foundation
import Testing
@testable import AnonyCore

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

@Suite("RemoteAuthServiceTests", .serialized)
struct RemoteAuthServiceTests {

    private let isolatedIdentityService = IdentityService(serviceIdentifier: "com.anony.mobile.test.remoteauth")

    private func makeTestSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    @Test("Remote login succeeds with HTTP 200 and persists credentials to Keychain")
    func testSuccessfulRemoteLogin() async throws {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let identityService = isolatedIdentityService
        _ = identityService.clearSession()

        let authService = RemoteAuthService(
            baseURL: testBaseURL,
            session: testSession,
            identityService: identityService
        )

        let targetEmail = "priya.coach@anony.internal"
        let targetPassword = "AnonyDemo#2026"
        let expectedUserId = "11111111-2222-3333-4444-555555555555"
        let expectedToken = "jwt_live_token_sample_abc123"

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/api/v1/auth/login")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let responseJSON = """
            {
                "token": "\(expectedToken)",
                "expiresIn": 86400,
                "user": {
                    "userId": "\(expectedUserId)",
                    "email": "\(targetEmail)",
                    "role": "COACH"
                }
            }
            """
            let responseData = responseJSON.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        let session = try await authService.login(email: targetEmail, password: targetPassword)

        #expect(session.token == expectedToken)
        #expect(session.email == targetEmail)
        #expect(!session.alias.isEmpty)
        #expect(!session.avatarId.isEmpty)
        #expect(identityService.hasActiveSession())
        #expect(identityService.fetchToken() == expectedToken)
        #expect(identityService.fetchEmail() == targetEmail)
    }

    @Test("Remote login throws invalidCredentials on HTTP 401")
    func testRemoteLoginUnauthorized() async {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let authService = RemoteAuthService(baseURL: testBaseURL, session: testSession)

        MockURLProtocol.requestHandler = { request in
            let errorJSON = "{\"error\": \"Invalid email or password.\"}"
            let responseData = errorJSON.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        await #expect(throws: AuthError.invalidCredentials) {
            _ = try await authService.login(email: "wrong@anony.internal", password: "Password#12345")
        }
    }

    @Test("Remote login throws registrationFailed on HTTP 400 Bad Request")
    func testRemoteLoginBadRequest() async {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let authService = RemoteAuthService(baseURL: testBaseURL, session: testSession)

        MockURLProtocol.requestHandler = { request in
            let errorJSON = "{\"error\": \"Malformed request payload\"}"
            let responseData = errorJSON.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        await #expect(throws: AuthError.registrationFailed("Malformed request payload")) {
            _ = try await authService.login(email: "bad@anony.internal", password: "Password#12345")
        }
    }

    @Test("Remote login client-side email and password validation rules")
    func testRemoteLoginClientValidation() async {
        let testSession = makeTestSession()
        let authService = RemoteAuthService(session: testSession)

        await #expect(throws: AuthError.invalidEmail) {
            _ = try await authService.login(email: "invalid-email", password: "ValidPassword#123")
        }

        await #expect(throws: AuthError.passwordTooShort) {
            _ = try await authService.login(email: "valid@anony.internal", password: "short")
        }

        await #expect(throws: AuthError.passwordTooLong) {
            _ = try await authService.login(email: "valid@anony.internal", password: String(repeating: "p", count: 33))
        }
    }

    @Test("Remote logout sends Bearer token and clears Keychain session")
    func testSuccessfulRemoteLogout() async throws {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let identityService = isolatedIdentityService

        let testToken = "jwt_token_to_logout_xyz987"
        _ = identityService.saveSession(token: testToken, alias: "TranquilRiver42", email: "user@anony.internal")
        #expect(identityService.hasActiveSession())

        let authService = RemoteAuthService(
            baseURL: testBaseURL,
            session: testSession,
            identityService: identityService
        )

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/api/v1/auth/logout")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(testToken)")

            let responseJSON = "{\"message\": \"Logged out successfully\"}"
            let responseData = responseJSON.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        try await authService.logout()

        #expect(!identityService.hasActiveSession())
        #expect(identityService.fetchToken() == nil)
    }

    @Test("Remote logout without active token clears Keychain cleanly")
    func testRemoteLogoutWithoutToken() async throws {
        let testSession = makeTestSession()
        let identityService = isolatedIdentityService
        _ = identityService.clearSession()

        let authService = RemoteAuthService(session: testSession, identityService: identityService)

        try await authService.logout()

        #expect(!identityService.hasActiveSession())
    }

    @Test("Remote logout with network failure still purges local session")
    func testRemoteLogoutNetworkFailurePurgesKeychain() async throws {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let identityService = isolatedIdentityService

        _ = identityService.saveSession(token: "stale_token_123", alias: "CalmPine12", email: "user@anony.internal")
        #expect(identityService.hasActiveSession())

        let authService = RemoteAuthService(
            baseURL: testBaseURL,
            session: testSession,
            identityService: identityService
        )

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        try await authService.logout()

        #expect(!identityService.hasActiveSession())
    }

    @Test("Remote registration succeeds with HTTP 200 and persists credentials")
    func testRemoteRegistrationSuccess() async throws {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let identityService = isolatedIdentityService
        _ = identityService.clearSession()

        let authService = RemoteAuthService(
            baseURL: testBaseURL,
            session: testSession,
            identityService: identityService
        )

        let targetEmail = "new.user@anony.internal"
        let targetPassword = "ValidPassword#123"

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/api/v1/auth/register")
            #expect(request.httpMethod == "POST")

            let responseJSON = """
            {
                "token": "jwt_registered_token_123",
                "expiresIn": 86400,
                "user": {
                    "userId": "22222222-3333-4444-5555-666666666666",
                    "email": "\(targetEmail)",
                    "role": "CLIENT"
                }
            }
            """
            let responseData = responseJSON.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        let session = try await authService.register(email: targetEmail, password: targetPassword)
        #expect(session.email == targetEmail)
        #expect(identityService.hasActiveSession())
    }

    @Test("Remote registration throws descriptive error on HTTP 404")
    func testRemoteRegistrationNotFound() async {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let authService = RemoteAuthService(baseURL: testBaseURL, session: testSession)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        await #expect(throws: AuthError.registrationFailed("Registration endpoint is not available on this server. Please use Sign In.")) {
            _ = try await authService.register(email: "new.user@anony.internal", password: "ValidPassword#123")
        }
    }
}
