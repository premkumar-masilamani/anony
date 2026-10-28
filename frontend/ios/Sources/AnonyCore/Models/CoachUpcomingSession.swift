import Foundation

/// Utility ensuring zero client PII is leaked in struggle essence descriptions.
public enum StruggleEssenceSanitizer {
    private static let emailRegex = try? NSRegularExpression(
        pattern: #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#,
        options: [.caseInsensitive]
    )

    private static let phoneRegex = try? NSRegularExpression(
        pattern: #"(?:\+?\d{1,3}[\s.-]?)?\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}"#,
        options: []
    )

    private static let urlRegex = try? NSRegularExpression(
        pattern: #"(?:https?:\/\/|www\.)\S+"#,
        options: [.caseInsensitive]
    )

    private static let handleRegex = try? NSRegularExpression(
        pattern: #"@[A-Za-z0-9_.-]+"#,
        options: []
    )

    private static let nameIntroRegex = try? NSRegularExpression(
        pattern: #"\b(?:my name is|i am|i'm|call me)\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?"#,
        options: [.caseInsensitive]
    )

    /// Inspects whether text contains potentially identifying PII (email, phone, URL, handle, or self-intro).
    public static func containsPII(_ text: String) -> Bool {
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)

        if let emailRegex, emailRegex.firstMatch(in: text, options: [], range: fullRange) != nil {
            return true
        }
        if let phoneRegex, phoneRegex.firstMatch(in: text, options: [], range: fullRange) != nil {
            return true
        }
        if let urlRegex, urlRegex.firstMatch(in: text, options: [], range: fullRange) != nil {
            return true
        }
        if let handleRegex, handleRegex.firstMatch(in: text, options: [], range: fullRange) != nil {
            return true
        }
        if let nameIntroRegex, nameIntroRegex.firstMatch(in: text, options: [], range: fullRange) != nil {
            return true
        }
        return false
    }

    /// Scrubs PII tokens from struggle essence text, replacing them with a redacted placeholder.
    public static func sanitize(_ text: String) -> String {
        var sanitized = text

        func replaceMatches(with regex: NSRegularExpression?, placeholder: String = "[redacted]") {
            guard let regex else { return }
            let range = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
            sanitized = regex.stringByReplacingMatches(
                in: sanitized,
                options: [],
                range: range,
                withTemplate: placeholder
            )
        }

        replaceMatches(with: emailRegex)
        replaceMatches(with: phoneRegex)
        replaceMatches(with: urlRegex)
        replaceMatches(with: handleRegex)
        replaceMatches(with: nameIntroRegex)

        // Collapse duplicate whitespace created by replacements
        let condensed = sanitized.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return condensed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Verifies that a client alias string does not leak email or other PII.
    public static func sanitizeAlias(_ alias: String, fallback: String = "Courageous Owl") -> String {
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.contains("@") || containsPII(trimmed) {
            return fallback
        }
        return trimmed
    }
}

/// Verified coaching session seen from the coach's perspective with strictly zero client personal identity.
public struct CoachUpcomingSession: Identifiable, Codable, Sendable, Equatable {
    /// Safe Room opens 10 minutes (600 seconds) prior to scheduled start.
    nonisolated public static let startSessionWindowSeconds: TimeInterval = 10 * 60

    public let id: UUID
    public let clientAlias: String
    public let clientAvatarSeed: String
    public let struggleEssence: String
    public let category: StruggleCategory
    public let scheduledStartAt: Date
    public let durationMinutes: Int
    public let isFreeProBono: Bool
    public let status: SessionStatus

    public init(
        id: UUID = UUID(),
        clientAlias: String,
        clientAvatarSeed: String? = nil,
        struggleEssence: String,
        category: StruggleCategory,
        scheduledStartAt: Date,
        durationMinutes: Int = 60,
        isFreeProBono: Bool = true,
        status: SessionStatus = .confirmed
    ) {
        self.id = id
        let sanitizedAlias = StruggleEssenceSanitizer.sanitizeAlias(clientAlias)
        self.clientAlias = sanitizedAlias
        self.clientAvatarSeed = clientAvatarSeed.map { StruggleEssenceSanitizer.sanitizeAlias($0) } ?? sanitizedAlias
        self.struggleEssence = StruggleEssenceSanitizer.sanitize(struggleEssence)
        self.category = category
        self.scheduledStartAt = scheduledStartAt
        self.durationMinutes = durationMinutes
        self.isFreeProBono = isFreeProBono
        self.status = status
    }

    public var scheduledEndAt: Date {
        scheduledStartAt.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    /// Seconds remaining until scheduled start relative to `referenceDate`.
    public func timeRemaining(from referenceDate: Date = Date()) -> TimeInterval {
        scheduledStartAt.timeIntervalSince(referenceDate)
    }

    /// Returns whether the coach can start the session and enter the Safe Room.
    /// Active 10 minutes prior to scheduled start until the session duration concludes.
    public func canStartSession(at referenceDate: Date = Date()) -> Bool {
        guard status != .completed && status != .cancelled else {
            return false
        }
        let remaining = timeRemaining(from: referenceDate)
        let sessionDuration = TimeInterval(durationMinutes * 60)
        return remaining <= Self.startSessionWindowSeconds && remaining > -sessionDuration
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

    /// Formats scheduled date in the coach's local timezone (e.g. "Thu, Oct 9, 2025").
    public func formattedDate(in timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: scheduledStartAt)
    }

    /// Formats scheduled start and end time range in the coach's local timezone (e.g. "9:00 AM - 10:00 AM IST").
    public func formattedTimeRange(in timeZone: TimeZone = .current) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = timeZone
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "h:mm a"

        let startStr = timeFormatter.string(from: scheduledStartAt)
        let endStr = timeFormatter.string(from: scheduledEndAt)
        let tzAbbreviation = timeZone.abbreviation(for: scheduledStartAt) ?? timeZone.identifier

        return "\(startStr) - \(endStr) \(tzAbbreviation)"
    }

    /// Converts into a `CoachingSession` domain model to interface with `SafeRoomServiceProtocol`.
    public func toCoachingSession(
        coachAlias: String = "Verified Coach",
        timeZone: TimeZone = .current
    ) -> CoachingSession {
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = timeZone
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "h:mm a"

        return CoachingSession(
            id: id,
            coachAlias: coachAlias,
            coachAvatarSeed: coachAlias,
            category: category,
            tier: isFreeProBono ? .free : .paid,
            scheduledDate: scheduledStartAt,
            timeSlot: timeFormatter.string(from: scheduledStartAt),
            timeZoneIdentifier: timeZone.identifier,
            status: status
        )
    }
}
