import Foundation

/// Status of an anonymous coaching session.
public enum SessionStatus: String, Codable, Sendable {
    case scheduled
    case confirmed
    case inProgress
    case completed
    case cancelled
}

/// Time-sensitive in-app notification alert rendered on a scheduled session card.
public enum SessionReminderAlert: Equatable, Sendable, Codable {
    case oneDayBefore(coachName: String)
    case twoHoursBefore
    case safeRoomOpen

    /// Human-readable reminder message adhering to zero-anxiety UI specifications.
    public var message: String {
        switch self {
        case .oneDayBefore(let coachName):
            let trimmed = coachName.trimmingCharacters(in: .whitespacesAndNewlines)
            let formattedCoach = trimmed.hasPrefix("Coach ") ? trimmed : "Coach \(trimmed)"
            return "Reminder: Your session with \(formattedCoach) is tomorrow."
        case .twoHoursBefore:
            return "Reminder: Session begins in 2 hours."
        case .safeRoomOpen:
            return "Safe Room is open."
        }
    }

    /// SF Symbol icon matching the alert's urgency level.
    public var systemImage: String {
        switch self {
        case .oneDayBefore:
            return "calendar.badge.clock"
        case .twoHoursBefore:
            return "clock.fill"
        case .safeRoomOpen:
            return "door.left.hand.open"
        }
    }
}

/// Coaching session booked or attended by the client.
public struct CoachingSession: Identifiable, Codable, Sendable, Equatable {
    /// Safe Room opens 10 minutes (600 seconds) prior to scheduled start.
    public static let safeRoomOpenWindowSeconds: TimeInterval = 10 * 60
    /// 2-hour reminder window (7,200 seconds) prior to scheduled start.
    public static let twoHourReminderWindowSeconds: TimeInterval = 2 * 3600
    /// 1-day reminder window (86,400 seconds) prior to scheduled start.
    public static let oneDayReminderWindowSeconds: TimeInterval = 24 * 3600
    /// Standard coaching session active duration (50 minutes).
    public static let defaultSessionDurationSeconds: TimeInterval = 50 * 60

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

    /// Seconds remaining until `scheduledDate` relative to `referenceDate`.
    public func timeRemaining(from referenceDate: Date = Date()) -> TimeInterval {
        scheduledDate.timeIntervalSince(referenceDate)
    }

    /// Evaluates the active in-app reminder alert for this session at `referenceDate`.
    public func reminderAlert(at referenceDate: Date = Date()) -> SessionReminderAlert? {
        guard status != .completed && status != .cancelled else {
            return nil
        }

        let remaining = timeRemaining(from: referenceDate)
        guard remaining > -Self.defaultSessionDurationSeconds else {
            return nil
        }

        if remaining <= Self.safeRoomOpenWindowSeconds {
            return .safeRoomOpen
        } else if remaining <= Self.twoHourReminderWindowSeconds {
            return .twoHoursBefore
        } else if remaining <= Self.oneDayReminderWindowSeconds {
            return .oneDayBefore(coachName: coachAlias)
        } else {
            return nil
        }
    }

    /// Returns whether the client can enter the WebRTC Safe Room at `referenceDate` (active 10 minutes before start).
    public func canEnterSafeRoom(at referenceDate: Date = Date()) -> Bool {
        guard status != .completed && status != .cancelled else {
            return false
        }

        let remaining = timeRemaining(from: referenceDate)
        return remaining <= Self.safeRoomOpenWindowSeconds && remaining > -Self.defaultSessionDurationSeconds
    }

    /// Formats the countdown timer relative to `referenceDate`.
    public func formattedCountdown(at referenceDate: Date = Date()) -> String {
        let totalSeconds = Int(ceil(timeRemaining(from: referenceDate)))
        guard totalSeconds > 0 else {
            return "Starting now"
        }

        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if days > 0 {
            return String(format: "%dd %02dh %02dm", days, hours, minutes)
        } else if hours > 0 {
            return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
        } else {
            return String(format: "%02dm %02ds", minutes, seconds)
        }
    }
}
