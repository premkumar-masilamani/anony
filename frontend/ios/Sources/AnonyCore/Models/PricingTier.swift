import Foundation

/// Coaching session pricing model tier.
public enum PricingTier: String, CaseIterable, Identifiable, Codable, Sendable {
    case free
    case paid

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .free:
            return "Community Pro-Bono Sanctuary"
        case .paid:
            return "Certified Specialist Coaching"
        }
    }

    public var subtitle: String {
        switch self {
        case .free:
            return "Zero cost, community-supported audio sanctuary with verified pro-bono guides."
        case .paid:
            return "Direct access to certified master coaches with deep domain specialization."
        }
    }

    public var systemImage: String {
        switch self {
        case .free:
            return "sparkles"
        case .paid:
            return "creditcard.fill"
        }
    }
}
