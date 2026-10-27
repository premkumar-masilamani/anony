import Testing
import Foundation
@testable import AnonyCore

@Suite("AuthServiceTests")
struct AuthServiceTests {

    @Test("Registration succeeds with valid email and password")
    func testSuccessfulRegistration() async throws {
        let authService = MockAuthService()
        let email = "tranquil.user@anony.app"
        let password = "validPassword123"

        let session = try await authService.register(email: email, password: password)

        #expect(!session.token.isEmpty)
        #expect(!session.alias.isEmpty)
        #expect(!session.avatarId.isEmpty)
        #expect(session.email == email)
    }

    @Test("Registration fails when password is 8 characters or shorter")
    func testRegistrationFailsShortPassword() async {
        let authService = MockAuthService()
        let email = "user@anony.app"
        let shortPassword = "12345678" // 8 characters, must be > 8

        await #expect(throws: AuthError.passwordTooShort) {
            _ = try await authService.register(email: email, password: shortPassword)
        }
    }

    @Test("Registration fails when password exceeds 32 characters")
    func testRegistrationFailsLongPassword() async {
        let authService = MockAuthService()
        let email = "user@anony.app"
        let longPassword = String(repeating: "p", count: 33)

        await #expect(throws: AuthError.passwordTooLong) {
            _ = try await authService.register(email: email, password: longPassword)
        }
    }

    @Test("Registration fails when email is empty or malformed")
    func testRegistrationFailsEmptyEmail() async {
        let authService = MockAuthService()
        let password = "validPassword123"

        await #expect(throws: AuthError.invalidEmail) {
            _ = try await authService.register(email: "", password: password)
        }

        await #expect(throws: AuthError.invalidEmail) {
            _ = try await authService.register(email: "not-an-email", password: password)
        }

        await #expect(throws: AuthError.invalidEmail) {
            _ = try await authService.register(email: "user@domain", password: password)
        }
    }
}
