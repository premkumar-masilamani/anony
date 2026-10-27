import Foundation

/// Captured client preferences from the 3-step progressive onboarding stepper.
public struct OnboardingPreferences: Codable, Sendable, Equatable {
    public var struggleCategory: StruggleCategory
    public var pricingTier: PricingTier
    public var scheduledDate: Date
    public var timeSlot: String
    public var timeZoneIdentifier: String

    public init(
        struggleCategory: StruggleCategory,
        pricingTier: PricingTier,
        scheduledDate: Date,
        timeSlot: String,
        timeZoneIdentifier: String
    ) {
        self.struggleCategory = struggleCategory
        self.pricingTier = pricingTier
        self.scheduledDate = scheduledDate
        self.timeSlot = timeSlot
        self.timeZoneIdentifier = timeZoneIdentifier
    }
}
