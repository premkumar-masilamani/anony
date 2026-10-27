import Testing
import Foundation
@testable import AnonyCore

@Suite("IdentityServiceTests", .serialized)
struct IdentityServiceTests {

    @Test("Save and fetch token in Keychain")
    func testSaveAndFetchToken() {
        let service = IdentityService.shared
        _ = service.clearSession()

        let token = "test-jwt-token-12345"
        let saved = service.saveToken(token)
        #expect(saved == true)

        let fetched = service.fetchToken()
        #expect(fetched == token)

        _ = service.clearSession()
    }

    @Test("Save, fetch, and overwrite full session in Keychain")
    func testFullSessionStorage() {
        let service = IdentityService.shared
        _ = service.clearSession()

        let token = "jwt-session-xyz"
        let alias = "CalmOtter"
        let email = "user@test.org"
        let role = "COACH"

        let saved = service.saveSession(token: token, alias: alias, email: email, role: role)
        #expect(saved == true)

        #expect(service.fetchToken() == token)
        #expect(service.fetchAlias() == alias)
        #expect(service.fetchEmail() == email)
        #expect(service.fetchRole() == role)
        #expect(service.hasActiveSession() == true)

        // Test overwrite
        let newToken = "jwt-session-updated"
        let newAlias = "SereneFalcon"
        let newEmail = "updated@test.org"
        let newRole = "CLIENT"

        let updated = service.saveSession(token: newToken, alias: newAlias, email: newEmail, role: newRole)
        #expect(updated == true)

        #expect(service.fetchToken() == newToken)
        #expect(service.fetchAlias() == newAlias)
        #expect(service.fetchEmail() == newEmail)
        #expect(service.fetchRole() == newRole)

        // Clear
        let cleared = service.clearSession()
        #expect(cleared == true)
        #expect(service.fetchToken() == nil)
        #expect(service.fetchAlias() == nil)
        #expect(service.fetchEmail() == nil)
        #expect(service.fetchRole() == nil)
        #expect(service.hasActiveSession() == false)
    }
}
