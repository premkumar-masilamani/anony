import Foundation

/// Data transfer object returned by the backend coach profile endpoints.
public struct CoachProfileResponse: Codable, Sendable, Identifiable, Equatable {
    public var id: UUID { coachId }
    public let coachId: UUID
    public let userId: UUID
    public let email: String
    public let firstName: String
    public let lastName: String
    public let timezone: String
    public let biography: String?
    public let icfLevel: String
    public let icfAcc: Bool
    public let icfPcc: Bool
    public let icfMcc: Bool
    public let icfActc: Bool
    public let credentialDetails: String?
    public let isVerified: Bool
    public let isOnboarded: Bool
    public let domainCodes: [String]
    public let createdAt: Date

    public init(
        coachId: UUID,
        userId: UUID,
        email: String,
        firstName: String,
        lastName: String,
        timezone: String,
        biography: String? = nil,
        icfLevel: String,
        icfAcc: Bool,
        icfPcc: Bool,
        icfMcc: Bool,
        icfActc: Bool,
        credentialDetails: String? = nil,
        isVerified: Bool,
        isOnboarded: Bool,
        domainCodes: [String] = [],
        createdAt: Date = Date()
    ) {
        self.coachId = coachId
        self.userId = userId
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.timezone = timezone
        self.biography = biography
        self.icfLevel = icfLevel
        self.icfAcc = icfAcc
        self.icfPcc = icfPcc
        self.icfMcc = icfMcc
        self.icfActc = icfActc
        self.credentialDetails = credentialDetails
        self.isVerified = isVerified
        self.isOnboarded = isOnboarded
        self.domainCodes = domainCodes
        self.createdAt = createdAt
    }
}
