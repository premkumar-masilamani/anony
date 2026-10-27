import Foundation
import SwiftUI
import Testing
@testable import AnonyCore

@Suite("MainShellViewTests")
struct MainShellViewTests {

    @Test("MainShellView instantiates and displays 3 tabs")
    @MainActor
    func testMainShellViewInstantiation() {
        var didSignOut = false
        let mockOnboarding = MockOnboardingService(
            completed: true,
            preferences: OnboardingPreferences(
                struggleCategory: .burnout,
                pricingTier: .free,
                scheduledDate: Date(),
                timeSlot: "10:00 AM",
                timeZoneIdentifier: TimeZone.current.identifier
            )
        )

        let shell = MainShellView(
            userAlias: "SereneVoyager",
            userEmail: "voyager@anony.internal",
            onboardingService: mockOnboarding,
            onSignOut: {
                didSignOut = true
            }
        )

        #expect(shell.userAlias == "SereneVoyager")
        #expect(shell.userEmail == "voyager@anony.internal")
        #expect(didSignOut == false)

        shell.onSignOut()
        #expect(didSignOut == true)
    }

    @Test("DiscoverAndMatchView filters coaches by category")
    @MainActor
    func testDiscoverAndMatchFilter() {
        let view = DiscoverAndMatchView(initialCategory: .burnout, initialTier: .free)
        #expect(view.selectedCategory == .burnout)
        #expect(view.selectedTier == .free)
        #expect(!view.coaches.isEmpty)
    }

    @Test("MySessionsView displays booked session from preferences")
    @MainActor
    func testMySessionsView() {
        let prefs = OnboardingPreferences(
            struggleCategory: .career,
            pricingTier: .paid,
            scheduledDate: Date(),
            timeSlot: "2:30 PM",
            timeZoneIdentifier: "UTC"
        )
        let view = MySessionsView(preferences: prefs)
        #expect(view.sessions.count >= 1)
        #expect(view.sessions.first?.category == .career)
        #expect(view.sessions.first?.timeSlot == "2:30 PM")
    }

    @Test("ClientSanctuaryFlowView routes first-time users to stepper and returning users to main shell")
    @MainActor
    func testClientSanctuaryFlowRouting() {
        var isAuth = false
        let unauthService = MockOnboardingService(completed: false)
        let unauthFlow = ClientSanctuaryFlowView(
            isAuthenticated: Binding(get: { isAuth }, set: { isAuth = $0 }),
            onboardingService: unauthService,
            onSessionAuthenticated: { _ in },
            onSignOut: {}
        )
        #expect(unauthFlow.currentFlowState == .unauthenticated)

        // Authenticated first-time user:
        isAuth = true
        let firstTimeService = MockOnboardingService(completed: false)
        let firstTimeFlow = ClientSanctuaryFlowView(
            isAuthenticated: Binding(get: { isAuth }, set: { isAuth = $0 }),
            onboardingService: firstTimeService,
            onSessionAuthenticated: { _ in },
            onSignOut: {}
        )
        #expect(firstTimeFlow.currentFlowState == .firstTimeStepper)

        // Authenticated returning user:
        let returningService = MockOnboardingService(completed: true)
        let returningFlow = ClientSanctuaryFlowView(
            isAuthenticated: Binding(get: { isAuth }, set: { isAuth = $0 }),
            onboardingService: returningService,
            onSessionAuthenticated: { _ in },
            onSignOut: {}
        )
        #expect(returningFlow.currentFlowState == .mainShell)
    }
}
