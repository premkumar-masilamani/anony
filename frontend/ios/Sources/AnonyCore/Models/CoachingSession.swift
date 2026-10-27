import Foundation

/// Status of an anonymous coaching session.
public enum SessionStatus: String, Codable, Sendable {
    case scheduled
    case confirmed
    case inProgress
    case completed
    case cancelled
}

/// Coaching session booked or attended by the client.
public struct CoachingSession: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let coachAlias: String
    public let coachAvatarSeed: String
    public let category: StruggleCategory
    public let tier: PricingTier
    public let scheduledDate: Date
    public let timeSlot: String
    public let timeZoneIdentifier: String
    public let status: SessionStatus

    public init(
        id: UUID = UUID(),
        coachAlias: String,
        coachAvatarSeed: String,
        category: StruggleCategory,
        tier: PricingTier,
        scheduledDate: Date,
        timeSlot: String,
        timeZoneIdentifier: String,
        status: SessionStatus = .confirmed
    ) {
        self.id = id
        self.coachAlias = coachAlias
        self.coachAvatarSeed = coachAvatarSeed
        self.category = category
        self.tier = tier
        self.scheduledDate = scheduledDate
        self.timeSlot = timeSlot
        self.timeZoneIdentifier = timeZoneIdentifier
        self.status = status
    }
}
