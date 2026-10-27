import Foundation

/// Represents a client's profile, personal information, and anonymity settings.
public struct ClientProfile: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var alias: String
    public var fullName: String
    public var email: String
    public var isAnonymousMode: Bool
    public var preferredLanguage: String
    public var timeZoneIdentifier: String
    public var primaryFocus: StruggleCategory
    public var freeSessionsUsed: Int
    public var maxFreeSessions: Int
    public var lastFreeSessionDate: Date?

    public init(
        id: UUID = UUID(),
        alias: String = "TranquilClient",
        fullName: String = "",
        email: String = "",
        isAnonymousMode: Bool = true,
        preferredLanguage: String = "English",
        timeZoneIdentifier: String = TimeZone.current.identifier,
        primaryFocus: StruggleCategory = .burnout,
        freeSessionsUsed: Int = 0,
        maxFreeSessions: Int = 6,
        lastFreeSessionDate: Date? = nil
    ) {
        self.id = id
        self.alias = alias
        self.fullName = fullName
        self.email = email
        self.isAnonymousMode = isAnonymousMode
        self.preferredLanguage = preferredLanguage
        self.timeZoneIdentifier = timeZoneIdentifier
        self.primaryFocus = primaryFocus
        self.freeSessionsUsed = freeSessionsUsed
        self.maxFreeSessions = maxFreeSessions
        self.lastFreeSessionDate = lastFreeSessionDate
    }

    /// Whether the 14-day (2-week) cooldown period is currently active.
    public func isCooldownActive(now: Date = Date()) -> Bool {
        guard let lastDate = lastFreeSessionDate else { return false }
        let cooldownDuration: TimeInterval = 14 * 86400 // 14 days in seconds
        return now.timeIntervalSince(lastDate) < cooldownDuration
    }

    /// Days remaining until the next free pro-bono session unlocks.
    public func daysUntilNextFreeSession(now: Date = Date()) -> Int {
        guard let lastDate = lastFreeSessionDate else { return 0 }
        let cooldownDuration: TimeInterval = 14 * 86400
        let elapsed = now.timeIntervalSince(lastDate)
        let remaining = cooldownDuration - elapsed
        if remaining <= 0 { return 0 }
        return Int(ceil(remaining / 86400))
    }

    /// Whether the client has consumed their maximum lifetime allowance of free pro-bono sessions.
    public var hasReachedLifetimeCap: Bool {
        freeSessionsUsed >= maxFreeSessions
    }

    /// Whether the client is currently eligible to book a free pro-bono session.
    public func canBookFreeSession(now: Date = Date()) -> Bool {
        !hasReachedLifetimeCap && !isCooldownActive(now: now)
    }

    /// Generates a serene, procedural pseudonym alias derived from tranquil natural metaphors.
    public static func generateTranquilAlias() -> String {
        let prefixes = ["Tranquil", "Serene", "Gentle", "Calm", "Peaceful", "Silent", "Quiet", "Restful"]
        let nouns = ["River", "Pine", "Willow", "Breeze", "Creek", "Stone", "Meadow", "Cloud", "Harbor"]
        let randomPrefix = prefixes.randomElement() ?? "Tranquil"
        let randomNoun = nouns.randomElement() ?? "Meadow"
        let randomSuffix = Int.random(in: 10...99)
        return "\(randomPrefix)\(randomNoun)\(randomSuffix)"
    }
}
