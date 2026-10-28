import Foundation
import SwiftUI

/// ViewModel managing the coach's upcoming confirmed sessions, timezone conversions,
/// struggle essence presentation, and Safe Room initiation.
@MainActor
public final class CoachUpcomingSessionsViewModel: ObservableObject {
    @Published public var sessions: [CoachUpcomingSession]
    @Published public var currentDate: Date
    @Published public var coachTimeZone: TimeZone
    @Published public private(set) var connectionState: SafeRoomConnectionState = .disconnected
    @Published public private(set) var activeRoomToken: SafeRoomConnectionToken? = nil
    @Published public private(set) var activeSession: CoachUpcomingSession? = nil
    @Published public var errorMessage: String? = nil

    public let safeRoomService: SafeRoomServiceProtocol

    public init(
        sessions: [CoachUpcomingSession] = [],
        currentDate: Date = Date(),
        coachTimeZone: TimeZone = .current,
        safeRoomService: SafeRoomServiceProtocol? = nil
    ) {
        self.sessions = sessions
        self.currentDate = currentDate
        self.coachTimeZone = coachTimeZone
        self.safeRoomService = safeRoomService ?? LiveKitRoomManager()
    }

    /// Whether the coach is currently connected to an active WebRTC Safe Room session.
    public var isSafeRoomOpen: Bool {
        if case .connected = connectionState, activeSession != nil {
            return true
        }
        return false
    }

    /// Confirmed upcoming sessions sorted chronologically by start time.
    public var confirmedSessions: [CoachUpcomingSession] {
        sessions
            .filter { $0.status == .confirmed || $0.status == .inProgress || $0.status == .scheduled }
            .sorted { $0.scheduledStartAt < $1.scheduledStartAt }
    }

    /// Advances the internal reference time for countdown and Safe Room readiness evaluations.
    public func tick(to date: Date = Date()) {
        self.currentDate = date
    }

    /// Updates the coach's presentation timezone dynamically.
    public func updateCoachTimezone(identifier: String) {
        if let tz = TimeZone(identifier: identifier) {
            self.coachTimeZone = tz
        }
    }

    /// Indicates whether the coach can start the session (active within 10 minutes prior).
    public func canStartSession(for session: CoachUpcomingSession) -> Bool {
        session.canStartSession(at: currentDate)
    }

    /// Formats the session date in the coach's local timezone.
    public func formattedDate(for session: CoachUpcomingSession) -> String {
        session.formattedDate(in: coachTimeZone)
    }

    /// Formats the session time range in the coach's local timezone with timezone abbreviation.
    public func formattedTimeRange(for session: CoachUpcomingSession) -> String {
        session.formattedTimeRange(in: coachTimeZone)
    }

    /// Formats the countdown timer relative to `currentDate`.
    public func formattedCountdown(for session: CoachUpcomingSession) -> String {
        session.formattedCountdown(at: currentDate)
    }

    /// Connects to the WebRTC Safe Room when the coach taps 'Start Session'.
    public func startSession(_ session: CoachUpcomingSession) async {
        errorMessage = nil

        guard canStartSession(for: session) else {
            errorMessage = SafeRoomServiceError.safeRoomNotOpenYet.localizedDescription
            return
        }

        connectionState = .connecting(sessionId: session.id)

        do {
            let bridgeSession = session.toCoachingSession(
                coachAlias: "Verified Coach",
                timeZone: coachTimeZone
            )
            let token = try await safeRoomService.connectToSafeRoom(for: bridgeSession, at: currentDate)
            activeSession = session
            activeRoomToken = token
            connectionState = .connected(token)
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            connectionState = .failed(message)
        }
    }

    /// Disconnects from the current Safe Room.
    public func leaveSafeRoom() async {
        await safeRoomService.disconnect()
        activeSession = nil
        activeRoomToken = nil
        connectionState = .disconnected
    }

    /// Generates high-fidelity demo sessions adhering to zero-PII requirements and seeded DB data.
    nonisolated public static func defaultDemoSessions(referenceDate: Date = Date()) -> [CoachUpcomingSession] {
        [
            CoachUpcomingSession(
                id: UUID(uuidString: "90000000-0000-4000-8000-000000000099") ?? UUID(),
                clientAlias: "Courageous Owl",
                clientAvatarSeed: "Courageous Owl",
                struggleEssence: "Navigating engineering leadership burnout, overcoming cognitive fatigue, and setting sustainable team boundaries.",
                category: .burnout,
                scheduledStartAt: referenceDate.addingTimeInterval(5 * 60), // Ready to start now (5 mins before start)
                durationMinutes: 60,
                isFreeProBono: true,
                status: .confirmed
            ),
            CoachUpcomingSession(
                id: UUID(uuidString: "90000000-0000-4000-8000-000000000001") ?? UUID(),
                clientAlias: "Courageous Owl",
                clientAvatarSeed: "Courageous Owl",
                struggleEssence: "Feeling drained at work, wrestling with career crossroad decisions, and wanting clarity without judgment.",
                category: .career,
                scheduledStartAt: referenceDate.addingTimeInterval(3 * 24 * 3600), // 3 days away
                durationMinutes: 60,
                isFreeProBono: true,
                status: .confirmed
            )
        ]
    }
}
