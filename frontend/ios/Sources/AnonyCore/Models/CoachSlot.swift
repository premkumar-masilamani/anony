import Foundation

/// 1-on-1 audio coaching session time slot.
/// Stored in absolute UTC time and rendered dynamically in the client's local timezone.
public struct CoachSlot: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let coachId: UUID
    public let startTime: Date
    public let durationMinutes: Int
    public var isBooked: Bool

    public init(
        id: UUID = UUID(),
        coachId: UUID,
        startTime: Date,
        durationMinutes: Int = 50,
        isBooked: Bool = false
    ) {
        self.id = id
        self.coachId = coachId
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.isBooked = isBooked
    }

    /// Formats the slot start time in the given timezone (e.g. "2:30 PM").
    public func formattedTime(in timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }

    /// Formats the slot calendar day in the given timezone (e.g. "Tue, Oct 28").
    public func formattedDate(in timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: startTime)
    }

    /// Returns the timezone abbreviation or identifier for the given timezone (e.g. "EDT", "IST", "PST").
    public func timeZoneAbbreviation(in timeZone: TimeZone = .current) -> String {
        timeZone.abbreviation(for: startTime) ?? timeZone.identifier
    }

    /// Checks if this slot falls on the same calendar day as the given target date in the specified timezone.
    public func isSameDay(as targetDate: Date, in timeZone: TimeZone = .current) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.isDate(startTime, inSameDayAs: targetDate)
    }
}
