import Foundation

/// Verified anonymous client review for a human coach.
/// Ensures zero personally identifiable information (PII) is exposed.
public struct CoachTestimonial: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let clientAlias: String
    public let struggleCategory: StruggleCategory
    public let feedback: String
    public let rating: Double
    public let dateString: String

    public init(
        id: UUID = UUID(),
        clientAlias: String,
        struggleCategory: StruggleCategory,
        feedback: String,
        rating: Double = 5.0,
        dateString: String
    ) {
        self.id = id
        self.clientAlias = clientAlias
        self.struggleCategory = struggleCategory
        self.feedback = feedback
        self.rating = rating
        self.dateString = dateString
    }
}
