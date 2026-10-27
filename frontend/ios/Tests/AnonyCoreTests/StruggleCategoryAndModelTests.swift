import Foundation
import Testing
@testable import AnonyCore

@Suite("StruggleCategoryAndModelTests")
struct StruggleCategoryAndModelTests {

    @Test("StruggleCategory cases and metadata")
    func testStruggleCategoryCases() {
        let cases = StruggleCategory.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.career))
        #expect(cases.contains(.life))
        #expect(cases.contains(.burnout))

        for category in cases {
            #expect(!category.title.isEmpty)
            #expect(!category.subtitle.isEmpty)
            #expect(!category.systemImage.isEmpty)
            #expect(category.id == category.rawValue)
        }
    }

    @Test("StruggleCategory JSON Codable roundtrip")
    func testStruggleCategoryCodable() throws {
        let original = StruggleCategory.burnout
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StruggleCategory.self, from: encoded)
        #expect(decoded == original)
    }

    @Test("PricingTier cases and metadata")
    func testPricingTierCases() {
        let tiers = PricingTier.allCases
        #expect(tiers.count == 2)
        #expect(tiers.contains(.free))
        #expect(tiers.contains(.paid))

        for tier in tiers {
            #expect(!tier.title.isEmpty)
            #expect(!tier.subtitle.isEmpty)
            #expect(!tier.systemImage.isEmpty)
            #expect(tier.id == tier.rawValue)
        }
    }

    @Test("PricingTier JSON Codable roundtrip")
    func testPricingTierCodable() throws {
        let original = PricingTier.free
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PricingTier.self, from: encoded)
        #expect(decoded == original)
    }

    @Test("OnboardingPreferences roundtrip and properties")
    func testOnboardingPreferences() throws {
        let date = Date(timeIntervalSince1970: 1700000000)
        let prefs = OnboardingPreferences(
            struggleCategory: .career,
            pricingTier: .free,
            scheduledDate: date,
            timeSlot: "10:00 AM",
            timeZoneIdentifier: "America/Los_Angeles"
        )

        #expect(prefs.struggleCategory == .career)
        #expect(prefs.pricingTier == .free)
        #expect(prefs.scheduledDate == date)
        #expect(prefs.timeSlot == "10:00 AM")
        #expect(prefs.timeZoneIdentifier == "America/Los_Angeles")

        let encoded = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(OnboardingPreferences.self, from: encoded)
        #expect(decoded == prefs)
    }

    @Test("Coach model conforms to Identifiable and Codable")
    func testCoachModel() throws {
        let coach = Coach(
            id: UUID(),
            alias: "SageEcho",
            title: "Career & Executive Guide",
            specialty: .career,
            tier: .paid,
            rating: 4.95,
            sessionCount: 142,
            avatarSeed: "SageEcho"
        )

        #expect(coach.alias == "SageEcho")
        #expect(coach.specialty == .career)
        #expect(coach.tier == .paid)
        #expect(coach.rating == 4.95)
        #expect(!coach.availableSlots.isEmpty)

        let encoded = try JSONEncoder().encode(coach)
        let decoded = try JSONDecoder().decode(Coach.self, from: encoded)
        #expect(decoded.id == coach.id)
        #expect(decoded.alias == coach.alias)
    }

    @Test("CoachingSession model conforms to Identifiable and Codable")
    func testCoachingSessionModel() throws {
        let date = Date(timeIntervalSince1970: 1700000000)
        let session = CoachingSession(
            id: UUID(),
            coachAlias: "SereneMind",
            coachAvatarSeed: "SereneMind",
            category: .burnout,
            tier: .free,
            scheduledDate: date,
            timeSlot: "2:30 PM",
            timeZoneIdentifier: "UTC",
            status: .confirmed
        )

        #expect(session.coachAlias == "SereneMind")
        #expect(session.category == .burnout)
        #expect(session.status == .confirmed)

        let encoded = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(CoachingSession.self, from: encoded)
        #expect(decoded.id == session.id)
        #expect(decoded.coachAlias == session.coachAlias)
        #expect(decoded.status == session.status)
    }
}
