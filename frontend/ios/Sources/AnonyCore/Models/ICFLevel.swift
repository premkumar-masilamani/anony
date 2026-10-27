import Foundation

/// International Coaching Federation (ICF) credential levels.
public enum ICFLevel: String, CaseIterable, Identifiable, Codable, Sendable, Equatable {
    case acc = "ACC"
    case pcc = "PCC"
    case mcc = "MCC"

    public var id: String { rawValue }

    public var title: String { rawValue }

    public var badgeTitle: String {
        switch self {
        case .acc:
            return "ICF ACC"
        case .pcc:
            return "ICF PCC"
        case .mcc:
            return "ICF MCC"
        }
    }

    public var credentialName: String {
        switch self {
        case .acc:
            return "Associate Certified Coach"
        case .pcc:
            return "Professional Certified Coach"
        case .mcc:
            return "Master Certified Coach"
        }
    }

    public var minExperienceHours: Int {
        switch self {
        case .acc:
            return 100
        case .pcc:
            return 500
        case .mcc:
            return 2500
        }
    }
}
