import Foundation

/// Data transfer object representing a single availability slot payload submitted by a coach.
public struct CoachAvailabilitySlotPayload: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let startAt: Date
    public let endAt: Date
    public let durationMinutes: Int
    public let isFreePledge: Bool

    enum CodingKeys: String, CodingKey {
        case startAt
        case endAt
        case durationMinutes
        case isFreePledge
        case isFreePledgeSnake = "is_free_pledge"
    }

    public init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date? = nil,
        durationMinutes: Int = 60,
        isFreePledge: Bool
    ) {
        self.id = id
        self.startAt = startAt
        self.durationMinutes = durationMinutes
        self.endAt = endAt ?? startAt.addingTimeInterval(TimeInterval(durationMinutes * 60))
        self.isFreePledge = isFreePledge
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.startAt = try container.decode(Date.self, forKey: .startAt)
        self.endAt = try container.decode(Date.self, forKey: .endAt)
        self.durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        if let camel = try container.decodeIfPresent(Bool.self, forKey: .isFreePledge) {
            self.isFreePledge = camel
        } else {
            self.isFreePledge = try container.decode(Bool.self, forKey: .isFreePledgeSnake)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startAt, forKey: .startAt)
        try container.encode(endAt, forKey: .endAt)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(isFreePledge, forKey: .isFreePledge)
        try container.encode(isFreePledge, forKey: .isFreePledgeSnake)
    }

    /// Formats the slot start and end range in the given timezone (e.g. "2:00 PM – 3:00 PM").
    public func formattedTimeRange(in timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startAt)) – \(formatter.string(from: endAt))"
    }

    /// Formats the slot calendar day in the given timezone (e.g. "Thu, Oct 29").
    public func formattedDate(in timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: startAt)
    }
}

/// Request wrapper for publishing a batch of coach availability slots (`POST /api/v1/coaches/me/availabilities`).
public struct CoachAvailabilityPublishPayload: Codable, Sendable, Equatable {
    public let slots: [CoachAvailabilitySlotPayload]

    public init(slots: [CoachAvailabilitySlotPayload]) {
        self.slots = slots
    }
}

/// Response model representing a persisted coach availability slot returned by the backend.
public struct CoachAvailabilitySlotResponse: Codable, Sendable, Equatable, Identifiable {
    public let slotId: UUID
    public let coachId: UUID
    public let startAt: Date
    public let endAt: Date
    public let durationMinutes: Int
    public let isFreePledge: Bool
    public let isBooked: Bool

    public var id: UUID { slotId }

    enum CodingKeys: String, CodingKey {
        case slotId
        case coachId
        case startAt
        case endAt
        case durationMinutes
        case isFreePledge
        case isFreePledgeSnake = "is_free_pledge"
        case isBooked
    }

    public init(
        slotId: UUID = UUID(),
        coachId: UUID,
        startAt: Date,
        endAt: Date,
        durationMinutes: Int,
        isFreePledge: Bool,
        isBooked: Bool = false
    ) {
        self.slotId = slotId
        self.coachId = coachId
        self.startAt = startAt
        self.endAt = endAt
        self.durationMinutes = durationMinutes
        self.isFreePledge = isFreePledge
        self.isBooked = isBooked
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.slotId = try container.decode(UUID.self, forKey: .slotId)
        self.coachId = try container.decode(UUID.self, forKey: .coachId)
        self.startAt = try container.decode(Date.self, forKey: .startAt)
        self.endAt = try container.decode(Date.self, forKey: .endAt)
        self.durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        if let camel = try container.decodeIfPresent(Bool.self, forKey: .isFreePledge) {
            self.isFreePledge = camel
        } else {
            self.isFreePledge = try container.decode(Bool.self, forKey: .isFreePledgeSnake)
        }
        self.isBooked = try container.decodeIfPresent(Bool.self, forKey: .isBooked) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(slotId, forKey: .slotId)
        try container.encode(coachId, forKey: .coachId)
        try container.encode(startAt, forKey: .startAt)
        try container.encode(endAt, forKey: .endAt)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(isFreePledge, forKey: .isFreePledge)
        try container.encode(isFreePledge, forKey: .isFreePledgeSnake)
        try container.encode(isBooked, forKey: .isBooked)
    }
}
