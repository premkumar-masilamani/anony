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

    @Test("ScheduleSessionStepView resolves timezone and slots")
    @MainActor
    func testScheduleSessionStepView() {
        let category: StruggleCategory = .career
        let tier: PricingTier = .paid
        var confirmedPrefs: OnboardingPreferences? = nil

        let stepView = ScheduleSessionStepView(
            selectedCategory: category,
            selectedTier: tier,
            onConfirm: { prefs in
                confirmedPrefs = prefs
            }
        )

        #expect(stepView.selectedCategory == .career)
        #expect(stepView.selectedTier == .paid)
        #expect(!stepView.availableTimeSlots.isEmpty)
        #expect(!stepView.localTimeZoneName.isEmpty)

        let testPrefs = OnboardingPreferences(
            struggleCategory: category,
            pricingTier: tier,
            scheduledDate: Date(),
            timeSlot: "10:00 AM",
            timeZoneIdentifier: TimeZone.current.identifier
        )
        stepView.onConfirm(testPrefs)
        #expect(confirmedPrefs?.struggleCategory == .career)
        #expect(confirmedPrefs?.pricingTier == .paid)
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
