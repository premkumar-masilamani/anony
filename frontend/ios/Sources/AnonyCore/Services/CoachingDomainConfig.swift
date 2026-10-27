import Foundation

/// Represents a coaching domain specialization option.
public struct DomainOption: Codable, Sendable, Hashable, Identifiable {
    public var id: String { code }
    public let code: String
    public let label: String

    public init(code: String, label: String) {
        self.code = code
        self.label = label
    }
}

/// Static configuration providing available coaching domains and human-readable formatting.
public enum CoachingDomainConfig {

    /// Standard domain options seeded in the application.
    public static let standardDomains: [DomainOption] = [
        DomainOption(code: "CAREER", label: "Career"),
        DomainOption(code: "LEADERSHIP", label: "Leadership"),
        DomainOption(code: "BURNOUT", label: "Burnout"),
        DomainOption(code: "WORK_LIFE_BALANCE", label: "Work-Life Balance"),
        DomainOption(code: "CONFIDENCE", label: "Confidence"),
        DomainOption(code: "MINDSET", label: "Mindset"),
        DomainOption(code: "COMMUNICATION", label: "Communication"),
        DomainOption(code: "PURPOSE", label: "Purpose"),
        DomainOption(code: "BUSINESS", label: "Business"),
        DomainOption(code: "PRODUCTIVITY", label: "Productivity"),
        DomainOption(code: "LIFE_TRANSITIONS", label: "Life Transitions"),
        DomainOption(code: "RELATIONSHIPS", label: "Relationships"),
        DomainOption(code: "PARENTING", label: "Parenting"),
        DomainOption(code: "CREATIVITY", label: "Creativity"),
        DomainOption(code: "ACADEMIC", label: "Academic"),
        DomainOption(code: "HEALTH_WELLNESS", label: "Health & Wellness")
    ]

    /// Returns a readable label for a given domain code (e.g. "WORK_LIFE_BALANCE" -> "Work-Life Balance").
    public static func label(forCode code: String) -> String {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = standardDomains.first(where: { $0.code.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return match.label
        }

        // Format snake_case or uppercase code into readable Title Case
        let words = trimmed
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: " ")
            .filter { !$0.isEmpty }

        return words.map { word in
            let lower = word.lowercased()
            return lower.prefix(1).uppercased() + lower.dropFirst()
        }.joined(separator: " ")
    }

    /// Normalizes custom user domain text into an uppercase code identifier.
    public static func normalizeCode(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatted = trimmed
            .uppercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
        return formatted
    }
}
