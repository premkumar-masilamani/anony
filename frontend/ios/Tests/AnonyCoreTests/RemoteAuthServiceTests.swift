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

    @Test("Remote coach registration succeeds with HTTP 201 and establishes COACH session")
    func testRemoteCoachRegistrationSuccess() async throws {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let identityService = isolatedIdentityService
        _ = identityService.clearSession()

        let authService = RemoteAuthService(
            baseURL: testBaseURL,
            session: testSession,
            identityService: identityService
        )

        let targetEmail = "coach.dan@anony.internal"
        let targetPassword = "CoachPassword#123"

        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/api/v1/auth/register" {
                #expect(request.httpMethod == "POST")
                let loginJSON = """
                {
                    "token": "jwt_coach_session_token",
                    "expiresIn": 86400,
                    "user": {
                        "userId": "11111111-2222-3333-4444-555555555555",
                        "email": "\(targetEmail)",
                        "role": "COACH"
                    }
                }
                """
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, loginJSON.data(using: .utf8)!)
            }
            fatalError("Unexpected request: \(request)")
        }

        let payload = CoachRegistrationPayload(
            email: targetEmail,
            password: targetPassword,
            firstName: "Dan",
            lastName: "Okafor",
            icfLevel: "MCC",
            credentialDetails: "ICF-99881",
            domainCodes: ["LEADERSHIP"],
            timezone: "Europe/London",
            hourlyRate: 200.0
        )

        let session = try await authService.registerCoach(payload: payload)
        #expect(session.email == targetEmail)
        #expect(session.role == "COACH")
        #expect(identityService.fetchRole() == "COACH")
        #expect(identityService.hasActiveSession())
    }

    @Test("Remote fetch coach profile returns profile details")
    func testRemoteFetchCoachProfileSuccess() async throws {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let identityService = isolatedIdentityService
        _ = identityService.clearSession()
        _ = identityService.saveToken("valid_bearer_token")

        let authService = RemoteAuthService(
            baseURL: testBaseURL,
            session: testSession,
            identityService: identityService
        )

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/api/v1/coaches/me")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer valid_bearer_token")

            let profileJSON = """
            {
                "coachId": "20000000-0000-4000-8000-000000000001",
                "userId": "10000000-0000-4000-8000-000000000001",
                "email": "maya.raman@example.com",
                "firstName": "Maya",
                "lastName": "Raman",
                "timezone": "Asia/Kolkata",
                "icfLevel": "PCC",
                "icfAcc": false,
                "icfPcc": true,
                "icfMcc": false,
                "icfActc": false,
                "isVerified": true,
                "isOnboarded": true,
                "domainCodes": ["CAREER", "BURNOUT"],
                "createdAt": "2026-10-27T10:00:00Z"
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, profileJSON.data(using: .utf8)!)
        }

        let profile = try await authService.fetchCoachProfile()
        #expect(profile.email == "maya.raman@example.com")
        #expect(profile.isVerified == true)
        #expect(profile.icfLevel == "PCC")
    }

    @Test("Remote fetch client profile returns client profile details")
    func testRemoteFetchClientProfileSuccess() async throws {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let identityService = isolatedIdentityService
        _ = identityService.clearSession()
        _ = identityService.saveToken("valid_client_token")

        let authService = RemoteAuthService(
            baseURL: testBaseURL,
            session: testSession,
            identityService: identityService
        )

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/api/v1/clients/me")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer valid_client_token")

            let profileJSON = """
            {
                "clientId": "30000000-0000-4000-8000-000000000001",
                "userId": "10000000-0000-4000-8000-000000000101",
                "email": "arjun.mehta@example.com",
                "firstName": "Arjun",
                "lastName": "Mehta",
                "alias": "Courageous Owl",
                "isAnonymous": true,
                "isOnboarded": true,
                "createdAt": "2026-10-27T10:00:00Z"
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, profileJSON.data(using: .utf8)!)
        }

        let profile = try await authService.fetchClientProfile()
        #expect(profile.email == "arjun.mehta@example.com")
        #expect(profile.alias == "Courageous Owl")
        #expect(profile.isAnonymous == true)
        #expect(profile.isAnonymousMode == true)
    }

    @Test("Remote update client privacy mode sends PATCH /api/v1/clients/me and returns updated profile")
    func testRemoteUpdateClientPrivacyModeSuccess() async throws {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let identityService = isolatedIdentityService
        _ = identityService.clearSession()
        _ = identityService.saveToken("valid_client_token")

        let authService = RemoteAuthService(
            baseURL: testBaseURL,
            session: testSession,
            identityService: identityService
        )

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/api/v1/clients/me")
            #expect(request.httpMethod == "PATCH")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer valid_client_token")

            let profileJSON = """
            {
                "clientId": "30000000-0000-4000-8000-000000000001",
                "userId": "10000000-0000-4000-8000-000000000101",
                "email": "arjun.mehta@example.com",
                "firstName": "Arjun",
                "lastName": "Mehta",
                "alias": "Courageous Owl",
                "isAnonymous": true,
                "isOnboarded": true,
                "isAnonymousMode": false,
                "createdAt": "2026-10-27T10:00:00Z"
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, profileJSON.data(using: .utf8)!)
        }

        let updatedProfile = try await authService.updateClientPrivacyMode(isAnonymousMode: false)
        #expect(updatedProfile.isAnonymousMode == false)
    }

    @Test("Remote update coach profile sends PUT /api/v1/coaches/me and returns updated profile")
    func testRemoteUpdateCoachProfileSuccess() async throws {
        let testSession = makeTestSession()
        let testBaseURL = URL(string: "http://127.0.0.1:8080")!
        let identityService = isolatedIdentityService
        _ = identityService.clearSession()
        _ = identityService.saveToken("valid_coach_token")

        let authService = RemoteAuthService(
            baseURL: testBaseURL,
            session: testSession,
            identityService: identityService
        )

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/api/v1/coaches/me")
            #expect(request.httpMethod == "PUT")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer valid_coach_token")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let profileJSON = """
            {
                "coachId": "20000000-0000-4000-8000-000000000001",
                "userId": "10000000-0000-4000-8000-000000000001",
                "email": "maya.raman@example.com",
                "firstName": "UpdatedMaya",
                "lastName": "UpdatedRaman",
                "photoUrl": "https://example.com/photo.jpg",
                "gender": "FEMALE",
                "countryCode": "IN",
                "timezone": "Asia/Kolkata",
                "biography": "Updated leadership bio",
                "icfLevel": "MCC",
                "icfAcc": true,
                "icfPcc": true,
                "icfMcc": true,
                "icfActc": false,
                "credentialDetails": "ICF-MCC-1029",
                "hourlyRate": 250.0,
                "isVerified": false,
                "isOnboarded": true,
                "domainCodes": ["CAREER", "LEADERSHIP"],
                "createdAt": "2026-10-27T10:00:00Z"
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, profileJSON.data(using: .utf8)!)
        }

        let payload = CoachUpdatePayload(
            firstName: "UpdatedMaya",
            lastName: "UpdatedRaman",
            photoUrl: "https://example.com/photo.jpg",
            gender: "FEMALE",
            countryCode: "IN",
            timezone: "Asia/Kolkata",
            biography: "Updated leadership bio",
            icfLevel: "MCC",
            icfAcc: true,
            icfPcc: true,
            icfMcc: true,
            icfActc: false,
            credentialDetails: "ICF-MCC-1029",
            domainCodes: ["CAREER", "LEADERSHIP"],
            hourlyRate: 250.0
        )

        let updated = try await authService.updateCoachProfile(payload: payload)
        #expect(updated.firstName == "UpdatedMaya")
        #expect(updated.lastName == "UpdatedRaman")
        #expect(updated.icfMcc == true)
        #expect(updated.hourlyRate == 250.0)
    }
}
