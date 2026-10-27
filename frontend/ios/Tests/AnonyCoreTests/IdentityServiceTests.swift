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

        let saved = service.saveSession(token: token, alias: alias, email: email)
        #expect(saved == true)

        #expect(service.fetchToken() == token)
        #expect(service.fetchAlias() == alias)
        #expect(service.fetchEmail() == email)
        #expect(service.hasActiveSession() == true)

        // Test overwrite
        let newToken = "jwt-session-updated"
        let newAlias = "SereneFalcon"
        let newEmail = "updated@test.org"

        let updated = service.saveSession(token: newToken, alias: newAlias, email: newEmail)
        #expect(updated == true)

        #expect(service.fetchToken() == newToken)
        #expect(service.fetchAlias() == newAlias)
        #expect(service.fetchEmail() == newEmail)

        // Clear
        let cleared = service.clearSession()
        #expect(cleared == true)
        #expect(service.fetchToken() == nil)
        #expect(service.fetchAlias() == nil)
        #expect(service.fetchEmail() == nil)
        #expect(service.hasActiveSession() == false)
    }
}
