import Foundation
import Testing
import SwiftUI
@testable import AnonyCore

@MainActor
private final class MockCoachVerificationAuthService: AuthServiceProtocol, @unchecked Sendable {
    var responses: [Result<CoachProfileResponse, Error>] = []
    private(set) var fetchCoachProfileCallCount: Int = 0
    var updatedProfileResponse: CoachProfileResponse?

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
        guard !responses.isEmpty else {
            return Self.makeProfile(isVerified: false)
        }
        let next = responses.removeFirst()
        return try next.get()
    }

    func updateCoachProfile(payload: CoachUpdatePayload) async throws -> CoachProfileResponse {
        if let updated = updatedProfileResponse {
            return updated
        }
        return Self.makeProfile(firstName: payload.firstName, lastName: payload.lastName, isVerified: false)
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

    nonisolated static func makeProfile(
        firstName: String = "Elena",
        lastName: String = "Vance",
        isVerified: Bool
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
            biography: "Certified ICF executive coach.",
            icfLevel: "PCC",
            icfAcc: true,
            icfPcc: true,
            icfMcc: false,
            icfActc: false,
            credentialDetails: "ICF-PCC-8821",
            hourlyRate: 160.0,
            isVerified: isVerified,
            isOnboarded: true,
            domainCodes: ["CAREER", "BURNOUT"]
        )
    }
}

@Suite("CoachVerificationTests", .serialized)
struct CoachVerificationTests {

    @Test("CoachVerificationViewModel initializes with Under Review indicator and unverified state")
    @MainActor
    func testUnderReviewIndicatorAndInitialState() {
        let mockAuth = MockCoachVerificationAuthService()
        let viewModel = CoachVerificationViewModel(authService: mockAuth)

        #expect(viewModel.statusLabel == "Under Review")
        #expect(viewModel.isVerified == false)
        #expect(viewModel.isRefreshing == false)
        #expect(viewModel.profile == nil)

        let view = CoachVerificationPendingView(
            coachEmail: "elena.vance@example.com",
            authService: mockAuth,
            onVerified: {},
            onSignOut: {}
        )
        #expect(view.coachEmail == "elena.vance@example.com")
    }

    @Test("Pull-to-refresh checks GET /api/v1/coaches/me and keeps Under Review when unverified")
    @MainActor
    func testPullToRefreshChecksCoachMeEndpoint() async {
        let mockAuth = MockCoachVerificationAuthService()
        mockAuth.responses = [
            .success(MockCoachVerificationAuthService.makeProfile(isVerified: false))
        ]

        var verifiedTriggered = false
        let viewModel = CoachVerificationViewModel(
            authService: mockAuth,
            onVerified: { verifiedTriggered = true }
        )

        await viewModel.checkVerificationStatus()

        #expect(mockAuth.fetchCoachProfileCallCount == 1)
        #expect(viewModel.profile?.firstName == "Elena")
        #expect(viewModel.isVerified == false)
        #expect(viewModel.statusLabel == "Under Review")
        #expect(verifiedTriggered == false)
    }

    @Test("Pull-to-refresh immediately unlocks dashboard when is_verified becomes true")
    @MainActor
    func testPullToRefreshUnlocksWhenVerified() async {
        let mockAuth = MockCoachVerificationAuthService()
        mockAuth.responses = [
            .success(MockCoachVerificationAuthService.makeProfile(isVerified: true))
        ]

        var verifiedCount = 0
        let viewModel = CoachVerificationViewModel(
            authService: mockAuth,
            onVerified: { verifiedCount += 1 }
        )

        await viewModel.checkVerificationStatus()

        #expect(mockAuth.fetchCoachProfileCallCount == 1)
        #expect(viewModel.isVerified == true)
        #expect(viewModel.statusLabel == "Verified")
        #expect(verifiedCount == 1)
    }

    @Test("Polling checks GET /api/v1/coaches/me and stops automatically once is_verified is true")
    @MainActor
    func testPollingDetectsVerificationAndUnlocksDashboard() async {
        let mockAuth = MockCoachVerificationAuthService()
        mockAuth.responses = [
            .success(MockCoachVerificationAuthService.makeProfile(isVerified: false)),
            .success(MockCoachVerificationAuthService.makeProfile(isVerified: false)),
            .success(MockCoachVerificationAuthService.makeProfile(isVerified: true))
        ]

        var verifiedCount = 0
        let viewModel = CoachVerificationViewModel(
            authService: mockAuth,
            onVerified: { verifiedCount += 1 }
        )

        await viewModel.startPolling(intervalNanoseconds: 10_000_000)

        #expect(mockAuth.fetchCoachProfileCallCount == 3)
        #expect(viewModel.isVerified == true)
        #expect(verifiedCount == 1)
    }

    @Test("Polling and refresh handle transient network errors without falsely unlocking")
    @MainActor
    func testPollingAndRefreshResilienceOnNetworkError() async {
        let mockAuth = MockCoachVerificationAuthService()
        mockAuth.responses = [
            .failure(URLError(.notConnectedToInternet))
        ]

        var verifiedTriggered = false
        let viewModel = CoachVerificationViewModel(
            authService: mockAuth,
            onVerified: { verifiedTriggered = true }
        )

        await viewModel.checkVerificationStatus()

        #expect(mockAuth.fetchCoachProfileCallCount == 1)
        #expect(viewModel.isVerified == false)
        #expect(verifiedTriggered == false)
        #expect(viewModel.statusLabel == "Under Review")
    }

    @Test("CoachRootFlowView transitions seamlessly from verificationPending to verifiedDashboard and exposes 3-Screen Coach Dashboard")
    @MainActor
    func testCoachRootFlowUnlocksThreeScreenDashboardWhenVerified() {
        let mockAuth = MockCoachVerificationAuthService()
        var isVerified = false

        let pendingFlow = CoachRootFlowView(
             isCoachVerified: Binding(get: { isVerified }, set: { isVerified = $0 }),
            coachEmail: "elena.vance@example.com",
            authService: mockAuth,
            onSignOut: {}
        )
        #expect(pendingFlow.currentFlowState == .verificationPending)

        isVerified = true
        let verifiedFlow = CoachRootFlowView(
            isCoachVerified: Binding(get: { isVerified }, set: { isVerified = $0 }),
            coachEmail: "elena.vance@example.com",
            authService: mockAuth,
            onSignOut: {}
        )
        #expect(verifiedFlow.currentFlowState == .verifiedDashboard)

        #expect(CoachDashboardView.DashboardTab.allCases.count == 3)
        #expect(CoachDashboardView.DashboardTab.allCases == [.availability, .sessions, .profile])
    }

    @Test("CoachVerificationViewModel applyUpdatedProfile updates profile and status message")
    @MainActor
    func testApplyUpdatedProfile() {
        let mockAuth = MockCoachVerificationAuthService()
        var verifiedCount = 0
        let viewModel = CoachVerificationViewModel(
            authService: mockAuth,
            onVerified: { verifiedCount += 1 }
        )

        let updatedUnverified = MockCoachVerificationAuthService.makeProfile(
            firstName: "Elena",
            lastName: "Updated",
            isVerified: false
        )
        viewModel.applyUpdatedProfile(updatedUnverified)

        #expect(viewModel.profile?.lastName == "Updated")
        #expect(viewModel.isVerified == false)
        #expect(viewModel.statusMessage == "Profile updated and resubmitted for review.")
        #expect(verifiedCount == 0)

        let updatedVerified = MockCoachVerificationAuthService.makeProfile(
            firstName: "Elena",
            lastName: "Updated",
            isVerified: true
        )
        viewModel.applyUpdatedProfile(updatedVerified)

        #expect(viewModel.isVerified == true)
        #expect(verifiedCount == 1)
    }
}
