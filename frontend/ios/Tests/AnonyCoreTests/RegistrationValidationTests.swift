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

    @Test("Email syntax and format validation")
    func testEmailValidation() {
        // Empty and blank
        #expect(!RegistrationValidator.isValidEmail(""))
        #expect(!RegistrationValidator.isValidEmail("   "))

        // Malformed structure
        #expect(!RegistrationValidator.isValidEmail("plainaddress"))
        #expect(!RegistrationValidator.isValidEmail("@missingusername.com"))
        #expect(!RegistrationValidator.isValidEmail("username@.com"))
        #expect(!RegistrationValidator.isValidEmail("username@domain"))
        #expect(!RegistrationValidator.isValidEmail("username@domain."))
        #expect(!RegistrationValidator.isValidEmail("username@domain..com"))
        #expect(!RegistrationValidator.isValidEmail("username@domain.c")) // TLD must be >= 2 characters
        #expect(!RegistrationValidator.isValidEmail("user name@domain.com")) // whitespace in address

        // Valid email formats
        #expect(RegistrationValidator.isValidEmail("client@anony.app"))
        #expect(RegistrationValidator.isValidEmail("user@example.com"))
        #expect(RegistrationValidator.isValidEmail("first.last@company.org"))
        #expect(RegistrationValidator.isValidEmail("client+filter@domain.io"))
        #expect(RegistrationValidator.isValidEmail("user_123@sub.domain.co.uk"))
    }
}
