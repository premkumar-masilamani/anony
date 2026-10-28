import Foundation
import SwiftUI
import Testing
@testable import AnonyCore

@Suite("CoachUpcomingSessionsView & Struggle Essence Tests")
struct CoachUpcomingSessionsTests {

    private let baseReferenceDate = Date(timeIntervalSince1970: 1_760_000_000) // 2025-10-09 08:53:20 UTC

    private func makeCoachSession(
        id: UUID = UUID(uuidString: "90000000-0000-4000-8000-000000000099")!,
        clientAlias: String = "Courageous Owl",
        struggleEssence: String = "Navigating engineering leadership burnout and setting sustainable boundaries.",
        category: StruggleCategory = .burnout,
        scheduledOffsetSeconds: TimeInterval,
        durationMinutes: Int = 60,
        isFreeProBono: Bool = true,
        status: SessionStatus = .confirmed
    ) -> CoachUpcomingSession {
        CoachUpcomingSession(
            id: id,
            clientAlias: clientAlias,
            clientAvatarSeed: clientAlias,
            struggleEssence: struggleEssence,
            category: category,
            scheduledStartAt: baseReferenceDate.addingTimeInterval(scheduledOffsetSeconds),
            durationMinutes: durationMinutes,
            isFreeProBono: isFreeProBono,
            status: status
        )
    }

    // MARK: - 1. Client Alias ('Courageous Owl'), Abstract Avatar & Struggle Essence

    @Test("Displays Client Alias ('Courageous Owl'), Abstract Avatar, and sanitized Struggle Essence")
    @MainActor
    func testDisplaysClientAliasAbstractAvatarAndStruggleEssence() {
        let session = makeCoachSession(
            clientAlias: "Courageous Owl",
            struggleEssence: "Navigating engineering leadership burnout and setting sustainable boundaries.",
            scheduledOffsetSeconds: 5 * 60
        )

        #expect(session.clientAlias == "Courageous Owl")
        #expect(session.clientAvatarSeed == "Courageous Owl")
        #expect(session.struggleEssence == "Navigating engineering leadership burnout and setting sustainable boundaries.")

        // Verify procedural abstract avatar resolves deterministic Owl icon without any photo/PII
        let avatar = AvatarCircleView(seed: session.clientAvatarSeed, size: .medium, showAura: true)
        #expect(avatar.params.symbolName == "bird.fill")

        let viewModel = CoachUpcomingSessionsViewModel(
            sessions: [session],
            currentDate: baseReferenceDate,
            coachTimeZone: TimeZone(identifier: "Asia/Kolkata")!
        )
        let view = CoachUpcomingSessionsView(
            viewModel: viewModel,
            coachTimezoneIdentifier: "Asia/Kolkata"
        )

        #expect(view.viewModel.confirmedSessions.count == 1)
        #expect(view.viewModel.confirmedSessions.first?.clientAlias == "Courageous Owl")
        #expect(view.viewModel.confirmedSessions.first?.struggleEssence == "Navigating engineering leadership burnout and setting sustainable boundaries.")
    }

    // MARK: - 2. Strictly Zero Client PII Displayed & Sanitized

    @Test("Strictly zero client PII is stored on CoachUpcomingSession or displayed in Struggle Essence")
    @MainActor
    func testStrictlyZeroClientPIIDisplayedAndSanitized() {
        let rawUnsanitizedEssence = """
        My name is Arjun Mehta and my email is arjun.mehta@example.com. \
        Call me at +1 (415) 555-0199 or DM @arjun_mehta at https://linkedin.com/in/arjunmehta \
        about feeling drained at work and unsure how to reset.
        """

        let session = makeCoachSession(
            clientAlias: "arjun.mehta@example.com", // Even if an email is accidentally passed as alias
            struggleEssence: rawUnsanitizedEssence,
            scheduledOffsetSeconds: 10 * 60
        )

        // 1. Alias fallback ensures email/PII is never rendered as the client alias
        #expect(session.clientAlias == "Courageous Owl")
        #expect(!session.clientAlias.contains("@"))
        #expect(!StruggleEssenceSanitizer.containsPII(session.clientAlias))

        // 2. Struggle essence strips email, phone, URL, social handle, and explicit name introduction
        #expect(!session.struggleEssence.contains("arjun.mehta@example.com"))
        #expect(!session.struggleEssence.contains("415"))
        #expect(!session.struggleEssence.contains("555-0199"))
        #expect(!session.struggleEssence.contains("@arjun_mehta"))
        #expect(!session.struggleEssence.contains("linkedin.com"))
        #expect(!session.struggleEssence.contains("Arjun Mehta"))
        #expect(session.struggleEssence.contains("feeling drained at work and unsure how to reset."))
        #expect(StruggleEssenceSanitizer.containsPII(session.struggleEssence) == false)

        // 3. Structural reflection check: CoachUpcomingSession has zero PII fields
        let propertyNames = Set(Mirror(reflecting: session).children.compactMap(\.label))
        let forbiddenPIIKeys: Set<String> = [
            "clientId", "userId", "email", "firstName", "lastName", "fullName", "realName", "phoneNumber", "photoUrl"
        ]
        #expect(propertyNames.isDisjoint(with: forbiddenPIIKeys))
    }

    // MARK: - 3. Sessions List in Coach's Local Timezone

    @Test("Sessions list formats UTC timestamps dynamically in the coach's local timezone")
    @MainActor
    func testSessionsFormattedInCoachLocalTimezone() {
        // 2025-10-09 13:30:00 UTC
        let utcStart = Date(timeIntervalSince1970: 1_760_016_600)
        let session = CoachUpcomingSession(
            clientAlias: "Courageous Owl",
            struggleEssence: "Feeling drained at work and unsure how to reset.",
            category: .burnout,
            scheduledStartAt: utcStart,
            durationMinutes: 60,
            status: .confirmed
        )

        let kolkataTZ = TimeZone(identifier: "Asia/Kolkata")! // UTC+5:30 -> 7:00 PM - 8:00 PM
        let newYorkTZ = TimeZone(identifier: "America/New_York")! // UTC-4 (EDT) -> 9:30 AM - 10:30 AM

        let viewModel = CoachUpcomingSessionsViewModel(
            sessions: [session],
            currentDate: baseReferenceDate,
            coachTimeZone: kolkataTZ
        )

        let kolkataTimeRange = viewModel.formattedTimeRange(for: session)
        let kolkataDate = viewModel.formattedDate(for: session)
        #expect(kolkataTimeRange.contains("7:00 PM - 8:00 PM"))
        #expect(kolkataDate == "Thu, Oct 9, 2025")

        // Dynamically switch coach timezone to America/New_York
        viewModel.updateCoachTimezone(identifier: "America/New_York")
        #expect(viewModel.coachTimeZone == newYorkTZ)

        let nyTimeRange = viewModel.formattedTimeRange(for: session)
        #expect(nyTimeRange.contains("9:30 AM - 10:30 AM"))
    }

    // MARK: - 4. Start Session Button Enabled 10 Minutes Prior to Session

    @Test("Start Session button is enabled exclusively within 10 minutes prior to session start")
    @MainActor
    func testStartSessionButtonEnabledTenMinutesPrior() {
        let session24h = makeCoachSession(scheduledOffsetSeconds: 24 * 3600)
        let session2h = makeCoachSession(scheduledOffsetSeconds: 2 * 3600)
        let session11m = makeCoachSession(scheduledOffsetSeconds: 11 * 60)
        let session10m = makeCoachSession(scheduledOffsetSeconds: 10 * 60)
        let session5m = makeCoachSession(scheduledOffsetSeconds: 5 * 60)
        let sessionInProgress = makeCoachSession(scheduledOffsetSeconds: -15 * 60, durationMinutes: 60)
        let sessionExpired = makeCoachSession(scheduledOffsetSeconds: -65 * 60, durationMinutes: 60)
        let sessionCancelled = makeCoachSession(scheduledOffsetSeconds: 5 * 60, status: .cancelled)
        let sessionCompleted = makeCoachSession(scheduledOffsetSeconds: 5 * 60, status: .completed)

        let viewModel = CoachUpcomingSessionsViewModel(
            sessions: [
                session24h, session2h, session11m, session10m,
                session5m, sessionInProgress, sessionExpired,
                sessionCancelled, sessionCompleted
            ],
            currentDate: baseReferenceDate
        )

        #expect(viewModel.canStartSession(for: session24h) == false)
        #expect(viewModel.canStartSession(for: session2h) == false)
        #expect(viewModel.canStartSession(for: session11m) == false)
        #expect(viewModel.canStartSession(for: session10m) == true)
        #expect(viewModel.canStartSession(for: session5m) == true)
        #expect(viewModel.canStartSession(for: sessionInProgress) == true)
        #expect(viewModel.canStartSession(for: sessionExpired) == false)
        #expect(viewModel.canStartSession(for: sessionCancelled) == false)
        #expect(viewModel.canStartSession(for: sessionCompleted) == false)

        // Advancing clock by 60 seconds brings the 11-minute session into the 10-minute window
        viewModel.tick(to: baseReferenceDate.addingTimeInterval(60))
        #expect(viewModel.canStartSession(for: session11m) == true)
    }

    // MARK: - 5. Start Session Button Opens Safe Room

    @Test("Start Session button opens encrypted WebRTC Safe Room when within 10-minute window")
    @MainActor
    func testStartSessionButtonOpensSafeRoom() async {
        let roomManager = LiveKitRoomManager()
        let readySession = makeCoachSession(
            clientAlias: "Courageous Owl",
            scheduledOffsetSeconds: 8 * 60
        )
        let viewModel = CoachUpcomingSessionsViewModel(
            sessions: [readySession],
            currentDate: baseReferenceDate,
            safeRoomService: roomManager
        )

        #expect(viewModel.connectionState == .disconnected)
        #expect(viewModel.isSafeRoomOpen == false)
        #expect(roomManager.connectCallCount == 0)

        await viewModel.startSession(readySession)

        #expect(roomManager.connectCallCount == 1)
        #expect(viewModel.activeSession == readySession)
        #expect(viewModel.activeRoomToken != nil)
        #expect(viewModel.activeRoomToken?.sessionId == readySession.id)
        #expect(viewModel.activeRoomToken?.endpoint == APIEndpoints.sessionJoinToken(id: readySession.id))
        #expect(viewModel.connectionState == .connected(viewModel.activeRoomToken!))
        #expect(viewModel.isSafeRoomOpen == true)

        await viewModel.leaveSafeRoom()
        #expect(viewModel.connectionState == .disconnected)
        #expect(viewModel.activeSession == nil)
        #expect(viewModel.isSafeRoomOpen == false)
    }

    @Test("Start Session rejects opening Safe Room when more than 10 minutes prior to session")
    @MainActor
    func testStartSessionRejectedBeforeTenMinuteWindow() async {
        let roomManager = LiveKitRoomManager()
        let futureSession = makeCoachSession(
            clientAlias: "Courageous Owl",
            scheduledOffsetSeconds: 45 * 60
        )
        let viewModel = CoachUpcomingSessionsViewModel(
            sessions: [futureSession],
            currentDate: baseReferenceDate,
            safeRoomService: roomManager
        )

        await viewModel.startSession(futureSession)

        #expect(roomManager.connectCallCount == 0)
        #expect(viewModel.connectionState == .disconnected)
        #expect(viewModel.activeSession == nil)
        #expect(viewModel.isSafeRoomOpen == false)
        #expect(viewModel.errorMessage == SafeRoomServiceError.safeRoomNotOpenYet.localizedDescription)
    }

    // MARK: - 6. Default Demo Sessions & Dashboard Integration

    @Test("Default demo sessions include 'Courageous Owl' with sanitized Struggle Essence and zero PII")
    @MainActor
    func testDefaultDemoSessionsAndDashboardIntegration() {
        let demoSessions = CoachUpcomingSessionsViewModel.defaultDemoSessions(referenceDate: baseReferenceDate)
        #expect(!demoSessions.isEmpty)

        let owlSession = demoSessions.first { $0.clientAlias == "Courageous Owl" }
        #expect(owlSession != nil)
        if let owlSession {
            #expect(!owlSession.struggleEssence.isEmpty)
            #expect(StruggleEssenceSanitizer.containsPII(owlSession.struggleEssence) == false)
            #expect(owlSession.canStartSession(at: baseReferenceDate) == true)
        }

        let dashboard = CoachDashboardView(
            coachEmail: "maya.raman@example.com",
            onSignOut: {}
        )
        #expect(dashboard.coachEmail == "maya.raman@example.com")
    }
}
