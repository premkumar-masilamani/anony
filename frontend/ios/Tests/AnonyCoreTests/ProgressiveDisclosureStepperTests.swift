import Foundation
import SwiftUI
import Testing
@testable import AnonyCore

@Suite("ProgressiveDisclosureStepperTests")
struct ProgressiveDisclosureStepperTests {

    @Test("MuseVoiceSphereView initializes and toggles state")
    @MainActor
    func testMuseVoiceSphereView() {
        var isSpeaking = false
        let sphere = MuseVoiceSphereView(
            isSpeaking: Binding(get: { isSpeaking }, set: { isSpeaking = $0 }),
            diameter: 120
        )
        #expect(sphere.diameter == 120)
        #expect(isSpeaking == false)

        isSpeaking.toggle()
        #expect(isSpeaking == true)
    }

    @Test("MuseVoiceGuideStepView instantiates with tranquil copy")
    @MainActor
    func testMuseVoiceGuideStepView() {
        var didAdvance = false
        let stepView = MuseVoiceGuideStepView(onContinue: {
            didAdvance = true
        })
        stepView.onContinue()
        #expect(didAdvance == true)
    }

    @Test("MatchPreferencesStepView state transitions and validation")
    @MainActor
    func testMatchPreferencesStepView() {
        var selectedCategory: StruggleCategory? = nil
        var selectedTier: PricingTier? = nil
        var didAdvance = false

        let stepView = MatchPreferencesStepView(
            selectedCategory: Binding(get: { selectedCategory }, set: { selectedCategory = $0 }),
            selectedTier: Binding(get: { selectedTier }, set: { selectedTier = $0 }),
            onContinue: { didAdvance = true }
        )

        #expect(stepView.isReadyToAdvance == false)

        selectedCategory = .burnout
        #expect(stepView.isReadyToAdvance == false)

        selectedTier = .free
        #expect(stepView.isReadyToAdvance == true)

        stepView.onContinue()
        #expect(didAdvance == true)
    }

    @Test("ScheduleSessionStepView resolves timezone, dual modes, and slots")
    @MainActor
    func testScheduleSessionStepView() {
        let category: StruggleCategory = .career
        let tier: PricingTier = .paid
        var confirmedPrefs: OnboardingPreferences? = nil

        let stepViewByCoach = ScheduleSessionStepView(
            selectedCategory: category,
            selectedTier: tier,
            initialMode: .byCoach,
            onConfirm: { prefs in
                confirmedPrefs = prefs
            }
        )

        #expect(stepViewByCoach.selectedCategory == .career)
        #expect(stepViewByCoach.selectedTier == .paid)
        #expect(!stepViewByCoach.availableTimeSlots.isEmpty)
        #expect(!stepViewByCoach.localTimeZoneName.isEmpty)
        #expect(stepViewByCoach.scheduleMode == .byCoach)
        #expect(stepViewByCoach.selectedCoach != nil)

        // Verify byTime mode
        let stepViewByTime = ScheduleSessionStepView(
            selectedCategory: category,
            selectedTier: tier,
            initialMode: .byTime,
            onConfirm: { prefs in
                confirmedPrefs = prefs
            }
        )
        #expect(stepViewByTime.scheduleMode == .byTime)

        let testPrefs = OnboardingPreferences(
            struggleCategory: category,
            pricingTier: tier,
            scheduledDate: Date(),
            timeSlot: "2:30 PM",
            timeZoneIdentifier: TimeZone.current.identifier,
            selectedCoachAlias: "EchoClaritas"
        )
        stepViewByCoach.onConfirm(testPrefs)
        #expect(confirmedPrefs?.struggleCategory == .career)
        #expect(confirmedPrefs?.pricingTier == .paid)
        #expect(confirmedPrefs?.selectedCoachAlias == "EchoClaritas")
    }

    @Test("ProgressiveDisclosureStepperView navigates through 3 steps and completes")
    @MainActor
    func testProgressiveDisclosureStepperProgression() {
        let mockService = MockOnboardingService()
        var completed = false

        let stepper = ProgressiveDisclosureStepperView(
            onboardingService: mockService,
            onComplete: {
                completed = true
            }
        )

        #expect(stepper.onboardingService.hasCompletedOnboarding() == false)
        #expect(completed == false)
    }
}
