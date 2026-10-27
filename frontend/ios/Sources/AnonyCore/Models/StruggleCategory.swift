import Foundation

/// Struggle categories that clients can seek coaching guidance for.
public enum StruggleCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case career
    case life
    case burnout

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .career:
            return "Career Transition & Growth"
        case .life:
            return "Life Direction & Purpose"
        case .burnout:
            return "Burnout & Stress Recovery"
        }
    }

    public var subtitle: String {
        switch self {
        case .career:
            return "Navigate crossroads, executive leadership, or meaningful career shifts."
        case .life:
            return "Restore personal alignment, relationships, and emotional balance."
        case .burnout:
            return "Recover energy, establish boundaries, and overcome chronic exhaustion."
        }
    }

    public var systemImage: String {
        switch self {
        case .career:
            return "briefcase.fill"
        case .life:
            return "heart.fill"
        case .burnout:
            return "flame.fill"
        }
    }
}
