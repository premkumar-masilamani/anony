import Foundation
import SwiftUI
import Testing
@testable import AnonyCore

@Suite("MySessionsView & Notification Alerts Tests")
struct MySessionsViewTests {

    private let baseReferenceDate = Date(timeIntervalSince1970: 1_760_000_000)

    private func makeSession(
        coachAlias: String = "Elena",
        scheduledOffsetSeconds: TimeInterval,
        status: SessionStatus = .confirmed
    ) -> CoachingSession {
        CoachingSession(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            coachAlias: coachAlias,
            coachAvatarSeed: coachAlias,
            category: .burnout,
            tier: .paid,
            scheduledDate: baseReferenceDate.addingTimeInterval(scheduledOffsetSeconds),
            timeSlot: "3:00 PM",
            timeZoneIdentifier: "UTC",
            status: status
        )
    }

    // MARK: - In-App Reminder Alerts

    @Test("1 day before reminder renders 'Reminder: Your session with Coach Elena is tomorrow.'")
    @MainActor
    func testOneDayBeforeReminderAlert() {
        // Exactly 24 hours before start
        let session24h = makeSession(coachAlias: "Elena", scheduledOffsetSeconds: 24 * 3600)
        let viewModel = MySessionsViewModel(sessions: [session24h], currentDate: baseReferenceDate)

        let alert = viewModel.reminderAlert(for: session24h)
        #expect(alert == .oneDayBefore(coachName: "Elena"))
        #expect(alert?.message == "Reminder: Your session with Coach Elena is tomorrow.")

        // Also verify when coachAlias already includes "Coach " prefix
        let sessionPrefixed = makeSession(coachAlias: "Coach Elena", scheduledOffsetSeconds: 18 * 3600)
        let prefixedAlert = sessionPrefixed.reminderAlert(at: baseReferenceDate)
        #expect(prefixedAlert?.message == "Reminder: Your session with Coach Elena is tomorrow.")
    }

    @Test("2 hours before reminder renders 'Reminder: Session begins in 2 hours.'")
    @MainActor
    func testTwoHoursBeforeReminderAlert() {
        // 2 hours before start (7,200 seconds)
        let session2h = makeSession(scheduledOffsetSeconds: 2 * 3600)
        let viewModel = MySessionsViewModel(sessions: [session2h], currentDate: baseReferenceDate)

        let alert = viewModel.reminderAlert(for: session2h)
        #expect(alert == .twoHoursBefore)
        #expect(alert?.message == "Reminder: Session begins in 2 hours.")

        // 45 minutes before start (still within the 2-hour window, > 10 minutes)
        let session45m = makeSession(scheduledOffsetSeconds: 45 * 60)
        #expect(session45m.reminderAlert(at: baseReferenceDate) == .twoHoursBefore)
        #expect(session45m.reminderAlert(at: baseReferenceDate)?.message == "Reminder: Session begins in 2 hours.")
    }

    @Test("10 minutes before reminder renders 'Safe Room is open.'")
    @MainActor
    func testTenMinutesBeforeSafeRoomOpenAlert() {
        // Exactly 10 minutes before start (600 seconds)
        let session10m = makeSession(scheduledOffsetSeconds: 10 * 60)
        let viewModel = MySessionsViewModel(sessions: [session10m], currentDate: baseReferenceDate)

        let alert = viewModel.reminderAlert(for: session10m)
        #expect(alert == .safeRoomOpen)
        #expect(alert?.message == "Safe Room is open.")

        // 2 minutes before start
        let session2m = makeSession(scheduledOffsetSeconds: 2 * 60)
        #expect(session2m.reminderAlert(at: baseReferenceDate) == .safeRoomOpen)
        #expect(session2m.reminderAlert(at: baseReferenceDate)?.message == "Safe Room is open.")
    }

    @Test("Sessions more than 24 hours away or cancelled/completed do not render reminder alerts")
    @MainActor
    func testMoreThanOneDayBeforeOrInactiveHasNoReminder() {
        let session3Days = makeSession(scheduledOffsetSeconds: 3 * 24 * 3600)
        let cancelledSession = makeSession(scheduledOffsetSeconds: 5 * 60, status: .cancelled)
        let completedSession = makeSession(scheduledOffsetSeconds: 5 * 60, status: .completed)

        let viewModel = MySessionsViewModel(
            sessions: [session3Days, cancelledSession, completedSession],
            currentDate: baseReferenceDate
        )

        #expect(viewModel.reminderAlert(for: session3Days) == nil)
        #expect(viewModel.reminderAlert(for: cancelledSession) == nil)
        #expect(viewModel.reminderAlert(for: completedSession) == nil)
    }

    // MARK: - Countdown Timer Formatting

    @Test("Scheduled session card formats countdown timer accurately across intervals")
    @MainActor
    func testCountdownFormattingAcrossIntervals() {
        let sessionDays = makeSession(scheduledOffsetSeconds: (2 * 86400) + (3 * 3600) + (15 * 60))
        let sessionHours = makeSession(scheduledOffsetSeconds: (2 * 3600) + (5 * 60) + 9)
        let sessionMinutes = makeSession(scheduledOffsetSeconds: (9 * 60) + 45)
        let sessionNow = makeSession(scheduledOffsetSeconds: 0)

        let viewModel = MySessionsViewModel(
            sessions: [sessionDays, sessionHours, sessionMinutes, sessionNow],
            currentDate: baseReferenceDate
        )

        #expect(viewModel.formattedCountdown(for: sessionDays) == "2d 03h 15m")
        #expect(viewModel.formattedCountdown(for: sessionHours) == "02h 05m 09s")
        #expect(viewModel.formattedCountdown(for: sessionMinutes) == "09m 45s")
        #expect(viewModel.formattedCountdown(for: sessionNow) == "Starting now")
    }

    // MARK: - Enter Safe Room Activation & WebRTC Connection

    @Test("Enter Safe Room button becomes active only within 10 minutes before session start")
    @MainActor
    func testEnterSafeRoomButtonActivationThreshold() {
        let session24h = makeSession(scheduledOffsetSeconds: 24 * 3600)
        let session2h = makeSession(scheduledOffsetSeconds: 2 * 3600)
        let session11m = makeSession(scheduledOffsetSeconds: 11 * 60)
        let session10m = makeSession(scheduledOffsetSeconds: 10 * 60)
        let session1m = makeSession(scheduledOffsetSeconds: 60)

        let viewModel = MySessionsViewModel(
            sessions: [session24h, session2h, session11m, session10m, session1m],
            currentDate: baseReferenceDate
        )

        #expect(viewModel.canEnterSafeRoom(for: session24h) == false)
        #expect(viewModel.canEnterSafeRoom(for: session2h) == false)
        #expect(viewModel.canEnterSafeRoom(for: session11m) == false)
        #expect(viewModel.canEnterSafeRoom(for: session10m) == true)
        #expect(viewModel.canEnterSafeRoom(for: session1m) == true)

        // Advancing time via tick unlocks the 11m session after 1 minute passes
        viewModel.tick(to: baseReferenceDate.addingTimeInterval(60))
        #expect(viewModel.canEnterSafeRoom(for: session11m) == true)
    }

    @Test("Enter Safe Room triggers WebRTC room connection when within 10-minute window")
    @MainActor
    func testEnterSafeRoomTriggersWebRTCConnection() async {
        let roomManager = LiveKitRoomManager()
        let openSession = makeSession(coachAlias: "Elena", scheduledOffsetSeconds: 8 * 60)
        let viewModel = MySessionsViewModel(
            sessions: [openSession],
            currentDate: baseReferenceDate,
            safeRoomService: roomManager
        )

        #expect(viewModel.connectionState == .disconnected)
        #expect(roomManager.connectCallCount == 0)

        await viewModel.enterSafeRoom(for: openSession)

        #expect(roomManager.connectCallCount == 1)
        #expect(viewModel.activeSession == openSession)
        #expect(viewModel.activeRoomToken != nil)
        #expect(viewModel.activeRoomToken?.sessionId == openSession.id)
        #expect(viewModel.activeRoomToken?.endpoint == APIEndpoints.sessionJoinToken(id: openSession.id))
        #expect(viewModel.connectionState == .connected(viewModel.activeRoomToken!))

        await viewModel.leaveSafeRoom()
        #expect(viewModel.connectionState == .disconnected)
        #expect(viewModel.activeSession == nil)
    }

    @Test("Enter Safe Room rejects WebRTC room connection when more than 10 minutes before start")
    @MainActor
    func testEnterSafeRoomRejectsEarlyConnection() async {
        let roomManager = LiveKitRoomManager()
        let earlySession = makeSession(coachAlias: "Elena", scheduledOffsetSeconds: 30 * 60)
        let viewModel = MySessionsViewModel(
            sessions: [earlySession],
            currentDate: baseReferenceDate,
            safeRoomService: roomManager
        )

        await viewModel.enterSafeRoom(for: earlySession)

        #expect(roomManager.connectCallCount == 0)
        #expect(viewModel.connectionState == .disconnected)
        #expect(viewModel.activeRoomToken == nil)
        #expect(viewModel.errorMessage == SafeRoomServiceError.safeRoomNotOpenYet.localizedDescription)
    }

    @Test("MySessionsView renders with ViewModel and supports direct session injection")
    @MainActor
    func testMySessionsViewWithInjectedSessions() {
        let session = makeSession(coachAlias: "Elena", scheduledOffsetSeconds: 5 * 60)
        let viewModel = MySessionsViewModel(sessions: [session], currentDate: baseReferenceDate)
        let view = MySessionsView(viewModel: viewModel)

        #expect(view.sessions.count == 1)
        #expect(view.sessions.first?.coachAlias == "Elena")
        #expect(view.viewModel.canEnterSafeRoom(for: session) == true)
        #expect(view.viewModel.reminderAlert(for: session)?.message == "Safe Room is open.")
    }
}
