import Foundation
import Testing
import SwiftUI
@testable import AnonyCore

@MainActor
private final class MockCoachDashboardAuthService: AuthServiceProtocol, @unchecked Sendable {
    var profileResult: Result<CoachProfileResponse, Error> = .success(MockCoachDashboardAuthService.makeVerifiedProfile())
    private(set) var fetchCoachProfileCallCount: Int = 0

    nonisolated func register(email: String, password: String) async throws -> AuthSession {
        AuthSession(token: "mock-token", alias: "Calm River", avatarId: "1", email: email, role: "CLIENT")
    }

    nonisolated func registerCoach(payload: CoachRegistrationPayload) async throws -> AuthSession {
        AuthSession(token: "mock-coach-token", alias: payload.firstName, avatarId: "1", email: payload.email, role: "COACH")
    }

    nonisolated func login(email: String, password: String) async throws -> AuthSession {
        AuthSession(token: "mock-token", alias: "Calm River", avatarId: "1", email: email, role: "COACH")
    }

    nonisolated func logout() async throws {}

    func fetchCoachProfile() async throws -> CoachProfileResponse {
        fetchCoachProfileCallCount += 1
        return try profileResult.get()
    }

    func updateCoachProfile(payload: CoachUpdatePayload) async throws -> CoachProfileResponse {
        Self.makeVerifiedProfile(firstName: payload.firstName, lastName: payload.lastName)
    }

    nonisolated func fetchClientProfile() async throws -> ClientProfileResponse {
        ClientProfileResponse(
            clientId: UUID(),
            userId: UUID(),
            email: "client@example.com",
            firstName: "Arjun",
            lastName: "Mehta",
            alias: "Calm River",
            isAnonymous: true,
            isOnboarded: true
        )
    }

    nonisolated static func makeVerifiedProfile(
        firstName: String = "Elena",
        lastName: String = "Vance",
        hourlyRate: Double = 160.0
    ) -> CoachProfileResponse {
        CoachProfileResponse(
            coachId: UUID(),
            userId: UUID(),
            email: "elena.vance@example.com",
            firstName: firstName,
            lastName: lastName,
            photoUrl: nil,
            gender: "FEMALE",
            countryCode: "US",
            timezone: "America/New_York",
            biography: "Certified ICF PCC executive & burnout recovery coach.",
            icfLevel: "PCC",
            icfAcc: true,
            icfPcc: true,
            icfMcc: false,
            icfActc: false,
            credentialDetails: "ICF-PCC-8821",
            hourlyRate: hourlyRate,
            isVerified: true,
            isOnboarded: true,
            domainCodes: ["CAREER", "BURNOUT"]
        )
    }
}

@Suite("CoachDashboardViewTests", .serialized)
struct CoachDashboardViewTests {

    @Test("DashboardTab defines exact 3-screen order, titles, short labels, subtitles, and SF Symbol icons")
    func testDashboardTabsOrderAndMetadata() {
        let tabs = CoachDashboardView.DashboardTab.allCases
        #expect(tabs.count == 3)
        #expect(tabs == [.availability, .sessions, .profile])

        // Screen 1: Availability & Free Pledge
        #expect(CoachDashboardView.DashboardTab.availability.rawValue == 0)
        #expect(CoachDashboardView.DashboardTab.availability.id == 0)
        #expect(CoachDashboardView.DashboardTab.availability.title == "Availability & Free Pledge")
        #expect(CoachDashboardView.DashboardTab.availability.shortTabTitle == "Availability")
        #expect(CoachDashboardView.DashboardTab.availability.systemImage == "clock.badge.checkmark")
        #expect(!CoachDashboardView.DashboardTab.availability.subtitle.isEmpty)

        // Screen 2: Upcoming Sessions Calendar
        #expect(CoachDashboardView.DashboardTab.sessions.rawValue == 1)
        #expect(CoachDashboardView.DashboardTab.sessions.id == 1)
        #expect(CoachDashboardView.DashboardTab.sessions.title == "Upcoming Sessions Calendar")
        #expect(CoachDashboardView.DashboardTab.sessions.shortTabTitle == "Calendar")
        #expect(CoachDashboardView.DashboardTab.sessions.systemImage == "calendar.badge.clock")
        #expect(!CoachDashboardView.DashboardTab.sessions.subtitle.isEmpty)

        // Screen 3: Profile & Earnings Summary
        #expect(CoachDashboardView.DashboardTab.profile.rawValue == 2)
        #expect(CoachDashboardView.DashboardTab.profile.id == 2)
        #expect(CoachDashboardView.DashboardTab.profile.title == "Profile & Earnings Summary")
        #expect(CoachDashboardView.DashboardTab.profile.shortTabTitle == "Profile & Earnings")
        #expect(CoachDashboardView.DashboardTab.profile.systemImage == "person.text.rectangle")
        #expect(!CoachDashboardView.DashboardTab.profile.subtitle.isEmpty)
    }

    @Test("CoachDashboardView defaults to Screen 1 (Availability & Free Pledge) and supports custom initialTab")
    @MainActor
    func testDefaultAndCustomInitialTab() {
        let mockAuth = MockCoachDashboardAuthService()
        let profile = MockCoachDashboardAuthService.makeVerifiedProfile()

        let defaultDashboard = CoachDashboardView(
            coachEmail: "elena.vance@example.com",
            initialProfile: profile,
            authService: mockAuth,
            onSignOut: {}
        )
        #expect(defaultDashboard.initialTab == .availability)
        #expect(defaultDashboard.coachEmail == "elena.vance@example.com")

        let sessionsDashboard = CoachDashboardView(
            coachEmail: "elena.vance@example.com",
            initialTab: .sessions,
            initialProfile: profile,
            authService: mockAuth,
            onSignOut: {}
        )
        #expect(sessionsDashboard.initialTab == .sessions)

        let profileDashboard = CoachDashboardView(
            coachEmail: "elena.vance@example.com",
            initialTab: .profile,
            initialProfile: profile,
            authService: mockAuth,
            onSignOut: {}
        )
        #expect(profileDashboard.initialTab == .profile)
    }

    @Test("CoachEarningsSummarySnapshot computes Gross Bookings, 10% Platform Fee, and 90% Net Payable balance")
    func testEarningsSummarySnapshotCalculation() {
        let zeroSnapshot = CoachDashboardView.EarningsSummarySnapshot(
            completedPaidSessions: 0,
            hourlyRate: 160.0
        )
        #expect(zeroSnapshot.grossBookings == 0.0)
        #expect(zeroSnapshot.platformFee == 0.0)
        #expect(zeroSnapshot.netPayable == 0.0)
        #expect(zeroSnapshot.formattedGrossBookings == "$0.00")
        #expect(zeroSnapshot.formattedPlatformFee == "-$0.00")
        #expect(zeroSnapshot.formattedNetPayable == "$0.00")

        let activeSnapshot = CoachDashboardView.EarningsSummarySnapshot(
            completedPaidSessions: 3,
            hourlyRate: 150.0
        )
        #expect(activeSnapshot.grossBookings == 450.0)
        #expect(activeSnapshot.platformFee == 45.0)
        #expect(activeSnapshot.netPayable == 405.0)
        #expect(activeSnapshot.formattedGrossBookings == "$450.00")
        #expect(activeSnapshot.formattedPlatformFee == "-$45.00")
        #expect(activeSnapshot.formattedNetPayable == "$405.00")
    }

    @Test("CoachDashboardView invokes sign-out handler and inspects view hierarchy across all 3 tabs")
    @MainActor
    func testSignOutCallbackAndViewMirror() {
        let mockAuth = MockCoachDashboardAuthService()
        let profile = MockCoachDashboardAuthService.makeVerifiedProfile()
        var signOutCount = 0

        for tab in CoachDashboardView.DashboardTab.allCases {
            let view = CoachDashboardView(
                coachEmail: profile.email,
                initialTab: tab,
                initialProfile: profile,
                authService: mockAuth,
                onSignOut: { signOutCount += 1 }
            )
            let bodyMirror = Mirror(reflecting: view.body)
            #expect(!bodyMirror.children.isEmpty)
        }

        let dashboard = CoachDashboardView(
            coachEmail: profile.email,
            initialProfile: profile,
            authService: mockAuth,
            onSignOut: { signOutCount += 1 }
        )
        dashboard.onSignOut()
        #expect(signOutCount == 1)
    }
}
