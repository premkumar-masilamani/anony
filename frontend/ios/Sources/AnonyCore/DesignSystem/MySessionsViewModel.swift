import Foundation
import SwiftUI

/// ViewModel driving `MySessionsView`, countdown timers, in-app notification alerts,
/// and WebRTC Safe Room connection triggers.
@MainActor
public final class MySessionsViewModel: ObservableObject {
    @Published public var sessions: [CoachingSession]
    @Published public var currentDate: Date
    @Published public private(set) var connectionState: SafeRoomConnectionState = .disconnected
    @Published public private(set) var activeRoomToken: SafeRoomConnectionToken? = nil
    @Published public private(set) var activeSession: CoachingSession? = nil
    @Published public var errorMessage: String? = nil

    public let safeRoomService: SafeRoomServiceProtocol

    public init(
        sessions: [CoachingSession] = [],
        currentDate: Date = Date(),
        safeRoomService: SafeRoomServiceProtocol? = nil
    ) {
        self.sessions = sessions
        self.currentDate = currentDate
        self.safeRoomService = safeRoomService ?? LiveKitRoomManager()
    }

    /// Updates the current reference time (invoked by the live countdown timer or tests).
    public func tick(to date: Date = Date()) {
        self.currentDate = date
    }

    /// Returns the contextual in-app reminder alert for `session` at `currentDate`.
    public func reminderAlert(for session: CoachingSession) -> SessionReminderAlert? {
        session.reminderAlert(at: currentDate)
    }

    /// Returns whether the `Enter Safe Room` button is active for `session` at `currentDate`.
    public func canEnterSafeRoom(for session: CoachingSession) -> Bool {
        session.canEnterSafeRoom(at: currentDate)
    }

    /// Returns the formatted countdown timer string for `session` at `currentDate`.
    public func formattedCountdown(for session: CoachingSession) -> String {
        session.formattedCountdown(at: currentDate)
    }

    /// Triggers the WebRTC Safe Room connection when `Enter Safe Room` is tapped.
    public func enterSafeRoom(for session: CoachingSession) async {
        errorMessage = nil

        guard canEnterSafeRoom(for: session) else {
            errorMessage = SafeRoomServiceError.safeRoomNotOpenYet.localizedDescription
            return
        }

        connectionState = .connecting(sessionId: session.id)
        do {
            let token = try await safeRoomService.connectToSafeRoom(for: session, at: currentDate)
            activeSession = session
            activeRoomToken = token
            connectionState = .connected(token)
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            connectionState = .failed(message)
        }
    }

    /// Leaves the currently connected WebRTC Safe Room.
    public func leaveSafeRoom() async {
        await safeRoomService.disconnect()
        activeSession = nil
        activeRoomToken = nil
        connectionState = .disconnected
    }
}
