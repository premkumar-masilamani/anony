import Foundation

public struct RegistrationValidator: Sendable {
    /// Validates password length: must be strictly longer than 8 characters and up to 32 characters.
    /// Per specifications: length > 8 and <= 32, no other validation needed.
    public static func isValidPassword(_ password: String) -> Bool {
        return password.count > 8 && password.count <= 32
    }

    /// Validates that an email is present and not blank.
    public static func isValidEmail(_ email: String) -> Bool {
        return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
