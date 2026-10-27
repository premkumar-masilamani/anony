import Foundation

/// Primary coaching domain topics for discovery directory filtering.
public enum CoachTopic: String, CaseIterable, Identifiable, Codable, Sendable, Equatable {
    case careerBurnout = "career_burnout"
    case relationship = "relationship"
    case life = "life"
    case executive = "executive"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .careerBurnout:
            return "Career & Burnout"
        case .relationship:
            return "Relationship"
        case .life:
            return "Life"
        case .executive:
            return "Executive"
        }
    }

    public var subtitle: String {
        switch self {
        case .careerBurnout:
            return "Burnout recovery, workplace exhaustion, career shifts, and boundary restoration."
        case .relationship:
            return "Communication strain, interpersonal dynamics, boundary setting, and empathy."
        case .life:
            return "Personal realignment, life transitions, existential clarity, and holistic balance."
        case .executive:
            return "Executive leadership, strategic clarity, high-stakes decision making, and team trust."
        }
    }

    public var systemImage: String {
        switch self {
        case .careerBurnout:
            return "flame.fill"
        case .relationship:
            return "person.2.fill"
        case .life:
            return "heart.fill"
        case .executive:
            return "crown.fill"
        }
    }
}
