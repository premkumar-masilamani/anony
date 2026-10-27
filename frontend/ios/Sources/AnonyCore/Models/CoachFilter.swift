import Foundation

/// Filter parameters for Coach Discovery Directory.
public struct CoachFilter: Equatable, Sendable {
    public var topic: CoachTopic?
    public var icfLevel: ICFLevel?
    public var tier: PricingTier?
    public var language: String?
    public var favoritesOnly: Bool

    public init(
        topic: CoachTopic? = nil,
        icfLevel: ICFLevel? = nil,
        tier: PricingTier? = nil,
        language: String? = nil,
        favoritesOnly: Bool = false
    ) {
        self.topic = topic
        self.icfLevel = icfLevel
        self.tier = tier
        self.language = language
        self.favoritesOnly = favoritesOnly
    }

    public var isDefault: Bool {
        topic == nil && icfLevel == nil && tier == nil && language == nil && !favoritesOnly
    }

    public func matches(coach: Coach, isFavorite: Bool) -> Bool {
        if let topic = topic, coach.topic != topic {
            return false
        }
        if let icfLevel = icfLevel, coach.icfLevel != icfLevel {
            return false
        }
        if let tier = tier, coach.tier != tier {
            return false
        }
        if let language = language, !coach.languages.contains(where: { $0.caseInsensitiveCompare(language) == .orderedSame }) {
            return false
        }
        if favoritesOnly && !isFavorite {
            return false
        }
        return true
    }
}
