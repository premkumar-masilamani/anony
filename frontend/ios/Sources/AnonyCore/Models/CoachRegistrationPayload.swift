import Foundation

/// Data transfer object for coach registration submissions.
public struct CoachRegistrationPayload: Codable, Sendable, Equatable {
    public let email: String
    public let password: String
    public let firstName: String
    public let lastName: String
    public let photoUrl: String?
    public let gender: String?
    public let countryCode: String?
    public let icfLevel: String?
    public let icfAcc: Bool?
    public let icfPcc: Bool?
    public let icfMcc: Bool?
    public let icfActc: Bool?
    public let credentialDetails: String?
    public let domainCodes: [String]
    public let timezone: String
    public let biography: String?
    public let hourlyRate: Double?

    public init(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        photoUrl: String? = nil,
        gender: String? = nil,
        countryCode: String? = nil,
        icfLevel: String? = nil,
        icfAcc: Bool? = nil,
        icfPcc: Bool? = nil,
        icfMcc: Bool? = nil,
        icfActc: Bool? = nil,
        credentialDetails: String? = nil,
        domainCodes: [String] = [],
        timezone: String = TimeZone.current.identifier,
        biography: String? = nil,
        hourlyRate: Double? = nil
    ) {
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
        self.photoUrl = photoUrl
        self.gender = gender
        self.countryCode = countryCode
        self.icfLevel = icfLevel
        self.icfAcc = icfAcc
        self.icfPcc = icfPcc
        self.icfMcc = icfMcc
        self.icfActc = icfActc
        self.credentialDetails = credentialDetails
        self.domainCodes = domainCodes
        self.timezone = timezone
        self.biography = biography
        self.hourlyRate = hourlyRate
    }
}
