import Foundation
import Testing
@testable import AnonyCore

@Suite("OnboardingServiceTests", .serialized)
struct OnboardingServiceTests {

    @Test("MockOnboardingService initial state is incomplete")
    func testMockInitialState() {
        let service = MockOnboardingService()
        #expect(service.hasCompletedOnboarding() == false)
        #expect(service.getPreferences() == nil)
    }

    @Test("MockOnboardingService setOnboardingCompleted toggles state")
    func testMockSetCompleted() {
        let service = MockOnboardingService()
        service.setOnboardingCompleted(true)
        #expect(service.hasCompletedOnboarding() == true)

        service.setOnboardingCompleted(false)
        #expect(service.hasCompletedOnboarding() == false)
    }

    @Test("MockOnboardingService save and retrieve preferences")
    func testMockPreferencesPersistence() {
        let service = MockOnboardingService()
        let prefs = OnboardingPreferences(
            struggleCategory: .burnout,
            pricingTier: .free,
            scheduledDate: Date(),
            timeSlot: "10:00 AM",
            timeZoneIdentifier: TimeZone.current.identifier
        )

        service.savePreferences(prefs)
        #expect(service.hasCompletedOnboarding() == true)
        let retrieved = service.getPreferences()
        #expect(retrieved?.struggleCategory == .burnout)
        #expect(retrieved?.pricingTier == .free)
        #expect(retrieved?.timeSlot == "10:00 AM")
    }

    @Test("UserDefaultsOnboardingService saves and resets cleanly")
    func testUserDefaultsOnboardingService() {
        let testDefaults = UserDefaults(suiteName: "test.anony.onboarding.\(UUID().uuidString)")!
        let service = UserDefaultsOnboardingService(userDefaults: testDefaults)

        #expect(service.hasCompletedOnboarding() == false)
        #expect(service.getPreferences() == nil)

        let prefs = OnboardingPreferences(
            struggleCategory: .life,
            pricingTier: .paid,
            scheduledDate: Date(),
            timeSlot: "6:00 PM",
            timeZoneIdentifier: "UTC"
        )

        service.savePreferences(prefs)
        #expect(service.hasCompletedOnboarding() == true)
        #expect(service.getPreferences()?.struggleCategory == .life)
        #expect(service.getPreferences()?.pricingTier == .paid)

        service.reset()
        #expect(service.hasCompletedOnboarding() == false)
        #expect(service.getPreferences() == nil)
    }
}
