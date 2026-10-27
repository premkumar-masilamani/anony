import Foundation

/// Preferred time window for automated pro-bono blind matches.
public enum BlindMatchTimeWindow: String, CaseIterable, Identifiable, Codable, Sendable {
    case morning = "MORNING"
    case afternoon = "AFTERNOON"
    case evening = "EVENING"
    case anytime = "ANYTIME"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .morning:
            return "Morning (9am - 12pm)"
        case .afternoon:
            return "Afternoon (12pm - 5pm)"
        case .evening:
            return "Evening (5pm - 9pm)"
        case .anytime:
            return "Anytime"
        }
    }

    public var systemImage: String {
        switch self {
        case .morning:
            return "sun.horizon.fill"
        case .afternoon:
            return "sun.max.fill"
        case .evening:
            return "moon.stars.fill"
        case .anytime:
            return "clock.fill"
        }
    }
}

/// Represents an atomically confirmed pro-bono coaching session returned from blind matching.
public struct ScheduledBlindMatchSession: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let coachAlias: String
    public let coachIcfLevel: String
    public let topic: String
    public let scheduledTime: Date
    public let status: String
    public let isProBono: Bool
    public let freeSessionsUsed: Int
    public let maxFreeSessions: Int
    public let nextFreeSessionAvailableAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "session_id"
        case coachAlias = "coach_alias"
        case coachIcfLevel = "coach_icf_level"
        case topic
        case scheduledTime = "scheduled_time"
        case status
        case isProBono = "is_pro_bono"
        case freeSessionsUsed = "free_sessions_used"
        case maxFreeSessions = "max_free_sessions"
        case nextFreeSessionAvailableAt = "next_free_session_available_at"
    }

    public init(
        id: UUID = UUID(),
        coachAlias: String,
        coachIcfLevel: String = "PCC",
        topic: String,
        scheduledTime: Date,
        status: String = "CONFIRMED",
        isProBono: Bool = true,
        freeSessionsUsed: Int = 1,
        maxFreeSessions: Int = 6,
        nextFreeSessionAvailableAt: Date? = nil
    ) {
        self.id = id
        self.coachAlias = coachAlias
        self.coachIcfLevel = coachIcfLevel
        self.topic = topic
        self.scheduledTime = scheduledTime
        self.status = status
        self.isProBono = isProBono
        self.freeSessionsUsed = freeSessionsUsed
        self.maxFreeSessions = maxFreeSessions
        self.nextFreeSessionAvailableAt = nextFreeSessionAvailableAt
    }
}
