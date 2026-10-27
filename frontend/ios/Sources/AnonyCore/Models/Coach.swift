import Foundation

/// Professional or peer coach profile in the Anony sanctuary.
public struct Coach: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let alias: String
    public let title: String
    public let specialty: StruggleCategory
    public let tier: PricingTier
    public let rating: Double
    public let sessionCount: Int
    public let avatarSeed: String

    public init(
        id: UUID = UUID(),
        alias: String,
        title: String,
        specialty: StruggleCategory,
        tier: PricingTier,
        rating: Double,
        sessionCount: Int,
        avatarSeed: String
    ) {
        self.id = id
        self.alias = alias
        self.title = title
        self.specialty = specialty
        self.tier = tier
        self.rating = rating
        self.sessionCount = sessionCount
        self.avatarSeed = avatarSeed
    }
}
