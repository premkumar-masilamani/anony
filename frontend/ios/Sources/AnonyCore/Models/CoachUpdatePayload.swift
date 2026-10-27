import Foundation

/// Data transfer object for coach profile update submissions.
public struct CoachUpdatePayload: Codable, Sendable, Equatable {
    public let firstName: String
    public let lastName: String
    public let photoUrl: String?
    public let gender: String?
    public let countryCode: String?
    public let timezone: String
    public let biography: String?
    public let icfLevel: String?
    public let icfAcc: Bool
    public let icfPcc: Bool
    public let icfMcc: Bool
    public let icfActc: Bool
    public let credentialDetails: String?
    public let domainCodes: [String]
    public let hourlyRate: Double?

    public init(
        firstName: String,
        lastName: String,
        photoUrl: String? = nil,
        gender: String? = nil,
        countryCode: String? = nil,
        timezone: String = TimeZone.current.identifier,
        biography: String? = nil,
        icfLevel: String? = nil,
        icfAcc: Bool,
        icfPcc: Bool,
        icfMcc: Bool,
        icfActc: Bool,
        credentialDetails: String? = nil,
        domainCodes: [String] = [],
        hourlyRate: Double? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.photoUrl = photoUrl
        self.gender = gender
        self.countryCode = countryCode
        self.timezone = timezone
        self.biography = biography
        self.icfLevel = icfLevel
        self.icfAcc = icfAcc
        self.icfPcc = icfPcc
        self.icfMcc = icfMcc
        self.icfActc = icfActc
        self.credentialDetails = credentialDetails
        self.domainCodes = domainCodes
        self.hourlyRate = hourlyRate
    }
}
