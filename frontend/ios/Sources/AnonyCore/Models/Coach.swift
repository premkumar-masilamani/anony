import Foundation

/// Verified human coach profile in the Anony platform.
/// All coaching sessions are conducted strictly between human clients and human coaches.
public struct Coach: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let alias: String
    public let title: String
    public let specialty: StruggleCategory
    public let topic: CoachTopic
    public let tier: PricingTier
    public let icfLevel: ICFLevel
    public let languages: [String]
    public let hourlyRate: Int
    public let rating: Double
    public let sessionCount: Int
    public let avatarSeed: String
    public let availableSlots: [String]

    public init(
        id: UUID = UUID(),
        alias: String,
        title: String,
        specialty: StruggleCategory,
        topic: CoachTopic? = nil,
        tier: PricingTier,
        icfLevel: ICFLevel = .pcc,
        languages: [String] = ["English"],
        hourlyRate: Int? = nil,
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
        self.icfLevel = icfLevel
        self.languages = languages
        self.rating = rating
        self.sessionCount = sessionCount
        self.avatarSeed = avatarSeed
        self.availableSlots = availableSlots

        if let topic = topic {
            self.topic = topic
        } else {
            switch specialty {
            case .career:
                self.topic = .careerBurnout
            case .life:
                self.topic = .life
            case .burnout:
                self.topic = .careerBurnout
            }
        }

        if let hourlyRate = hourlyRate {
            self.hourlyRate = hourlyRate
        } else {
            self.hourlyRate = (tier == .free) ? 0 : 120
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, alias, title, specialty, topic, tier, icfLevel, languages, hourlyRate, rating, sessionCount, avatarSeed, availableSlots
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.alias = try container.decode(String.self, forKey: .alias)
        self.title = try container.decode(String.self, forKey: .title)
        let decodedSpecialty = try container.decode(StruggleCategory.self, forKey: .specialty)
        self.specialty = decodedSpecialty
        let decodedTier = try container.decode(PricingTier.self, forKey: .tier)
        self.tier = decodedTier

        if let decodedTopic = try container.decodeIfPresent(CoachTopic.self, forKey: .topic) {
            self.topic = decodedTopic
        } else {
            switch decodedSpecialty {
            case .career:
                self.topic = .careerBurnout
            case .life:
                self.topic = .life
            case .burnout:
                self.topic = .careerBurnout
            }
        }

        self.icfLevel = try container.decodeIfPresent(ICFLevel.self, forKey: .icfLevel) ?? .pcc
        self.languages = try container.decodeIfPresent([String].self, forKey: .languages) ?? ["English"]
        self.hourlyRate = try container.decodeIfPresent(Int.self, forKey: .hourlyRate) ?? ((decodedTier == .free) ? 0 : 120)
        self.rating = try container.decode(Double.self, forKey: .rating)
        self.sessionCount = try container.decode(Int.self, forKey: .sessionCount)
        self.avatarSeed = try container.decode(String.self, forKey: .avatarSeed)
        self.availableSlots = try container.decodeIfPresent([String].self, forKey: .availableSlots) ?? ["Today 2:30 PM", "Tomorrow 10:00 AM"]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(alias, forKey: .alias)
        try container.encode(title, forKey: .title)
        try container.encode(specialty, forKey: .specialty)
        try container.encode(topic, forKey: .topic)
        try container.encode(tier, forKey: .tier)
        try container.encode(icfLevel, forKey: .icfLevel)
        try container.encode(languages, forKey: .languages)
        try container.encode(hourlyRate, forKey: .hourlyRate)
        try container.encode(rating, forKey: .rating)
        try container.encode(sessionCount, forKey: .sessionCount)
        try container.encode(avatarSeed, forKey: .avatarSeed)
        try container.encode(availableSlots, forKey: .availableSlots)
    }
}
