import Foundation

public struct RegistrationValidator: Sendable {
    /// Validates password length: must be strictly longer than 8 characters and up to 32 characters.
    /// Per specifications: length > 8 and <= 32, no other validation needed.
    public static func isValidPassword(_ password: String) -> Bool {
        return password.count > 8 && password.count <= 32
    }

    /// Validates email format: must be non-empty and conform to standard email syntax (e.g., user@domain.com).
    public static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9]+([.-][A-Za-z0-9]+)*\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }
}
