import Testing
import Foundation
@testable import AnonyCore

@Suite("RegistrationValidationTests")
struct RegistrationValidationTests {

    @Test("Password strictly shorter than or equal to 8 characters is invalid")
    func testPasswordTooShort() {
        #expect(!RegistrationValidator.isValidPassword(""))
        #expect(!RegistrationValidator.isValidPassword("1234"))
        #expect(!RegistrationValidator.isValidPassword("1234567"))
        #expect(!RegistrationValidator.isValidPassword("12345678")) // exactly 8 characters: must be > 8
    }

    @Test("Password between 9 and 32 characters inclusive is valid")
    func testPasswordValidRange() {
        #expect(RegistrationValidator.isValidPassword("123456789")) // 9 characters
        #expect(RegistrationValidator.isValidPassword("my-tranquil-password")) // 20 characters
        #expect(RegistrationValidator.isValidPassword(String(repeating: "a", count: 32))) // 32 characters
        #expect(RegistrationValidator.isValidPassword("P@ssw0rd!#$")) // symbols allowed
        #expect(RegistrationValidator.isValidPassword("pass word")) // spaces allowed, no other restrictions
    }

    @Test("Password longer than 32 characters is invalid")
    func testPasswordTooLong() {
        #expect(!RegistrationValidator.isValidPassword(String(repeating: "a", count: 33))) // 33 characters
        #expect(!RegistrationValidator.isValidPassword(String(repeating: "x", count: 64)))
    }

    @Test("Email presence check")
    func testEmailValidation() {
        #expect(!RegistrationValidator.isValidEmail(""))
        #expect(!RegistrationValidator.isValidEmail("   "))
        #expect(RegistrationValidator.isValidEmail("client@anony.app"))
        #expect(RegistrationValidator.isValidEmail("user@example.com"))
    }
}
