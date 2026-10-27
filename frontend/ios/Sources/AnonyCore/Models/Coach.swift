import Foundation

/// Verified human coach profile in the Anony platform.
/// All coaching sessions are conducted strictly between human clients and human coaches.
public struct Coach: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let alias: String
    public let title: String
    public let specialty: StruggleCategory
    public let tier: PricingTier
    public let rating: Double
    public let sessionCount: Int
    public let avatarSeed: String
    public let availableSlots: [String]

    public init(
        id: UUID = UUID(),
        alias: String,
        title: String,
        specialty: StruggleCategory,
        tier: PricingTier,
        rating: Double,
        sessionCount: Int,
        avatarSeed: String,
        availableSlots: [String] = ["Today 2:30 PM", "Tomorrow 10:00 AM", "Thu 4:00 PM"]
    ) {
        self.id = id
        self.alias = alias
        self.title = title
        self.specialty = specialty
        self.tier = tier
        self.rating = rating
        self.sessionCount = sessionCount
        self.avatarSeed = avatarSeed
        self.availableSlots = availableSlots
    }
}
