import Foundation

/// Data transfer object for coach registration submissions.
public struct CoachRegistrationPayload: Codable, Sendable, Equatable {
    public let email: String
    public let password: String
    public let firstName: String
    public let lastName: String
    public let icfLevel: String
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
        icfLevel: String,
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
        self.icfLevel = icfLevel
        self.credentialDetails = credentialDetails
        self.domainCodes = domainCodes
        self.timezone = timezone
        self.biography = biography
        self.hourlyRate = hourlyRate
    }
}
