import Foundation

/// Post-session reflection captured immediately following an anonymous coaching session.
/// Enforces strict architectural separation between public feedback (coach testimonial)
/// and private personal reflection notes (visible exclusively to the client).
public struct SessionReflection: Identifiable, Codable, Sendable, Equatable {
    public static let minRating: Int = 1
    public static let maxRating: Int = 5
    public static let availableQuickTags: [String] = [
        "Grounded",
        "Clarity",
        "Calm",
        "Actionable Steps",
        "Heard"
    ]

    public let id: UUID
    public let sessionId: UUID
    public let coachAlias: String
    public let rating: Int
    public let publicTestimonial: String?
    public let privateReflectionNote: String?
    public let quickTags: [String]
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        coachAlias: String,
        rating: Int,
        publicTestimonial: String? = nil,
        privateReflectionNote: String? = nil,
        quickTags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.coachAlias = coachAlias
        self.rating = rating
        self.publicTestimonial = publicTestimonial
        self.privateReflectionNote = privateReflectionNote
        self.quickTags = quickTags
        self.createdAt = createdAt
    }

    /// Evaluates if the rating falls within the permitted 1 to 5 scale.
    public var isValidRating: Bool {
        rating >= Self.minRating && rating <= Self.maxRating
    }

    /// Converts public testimonial content into a verified `CoachTestimonial`.
    /// Strictly guarantees that private reflection notes and client PII are NEVER included.
    public func toCoachTestimonial(
        clientAlias: String,
        category: StruggleCategory,
        dateString: String
    ) -> CoachTestimonial? {
        guard let publicTestimonial else { return nil }
        let trimmed = publicTestimonial.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        return CoachTestimonial(
            clientAlias: clientAlias,
            struggleCategory: category,
            feedback: trimmed,
            rating: Double(rating),
            dateString: dateString
        )
    }
}
