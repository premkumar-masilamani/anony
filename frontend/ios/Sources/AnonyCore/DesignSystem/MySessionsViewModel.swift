import Foundation
import SwiftUI

/// ViewModel driving `MySessionsView`, countdown timers, in-app notification alerts,
/// WebRTC Safe Room connection triggers, and post-session reflection flows.
@MainActor
public final class MySessionsViewModel: ObservableObject {
    @Published public var sessions: [CoachingSession]
    @Published public var currentDate: Date
    @Published public private(set) var connectionState: SafeRoomConnectionState = .disconnected
    @Published public private(set) var activeRoomToken: SafeRoomConnectionToken? = nil
    @Published public private(set) var activeSession: CoachingSession? = nil
    @Published public var errorMessage: String? = nil

    // Post-Session Reflection & In-App Notification States
    @Published public var pendingReflectionSession: CoachingSession? = nil
    @Published public var showReflectionSheet: Bool = false
    @Published public var reflectionSuccessMessage: String? = nil

    public let safeRoomService: SafeRoomServiceProtocol
    public let reflectionService: SessionReflectionServiceProtocol
    public let notificationManager: NotificationManagerProtocol

    public init(
        sessions: [CoachingSession] = [],
        currentDate: Date = Date(),
        safeRoomService: SafeRoomServiceProtocol? = nil,
        reflectionService: SessionReflectionServiceProtocol? = nil,
        notificationManager: NotificationManagerProtocol? = nil
    ) {
        self.sessions = sessions
        self.currentDate = currentDate
        self.safeRoomService = safeRoomService ?? LiveKitRoomManager()
        self.reflectionService = reflectionService ?? SessionReflectionService()
        self.notificationManager = notificationManager ?? NotificationManager.shared
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

    /// Leaves the currently connected WebRTC Safe Room and triggers the post-session reflection prompt.
    public func leaveSafeRoom() async {
        let endingSession = activeSession

        await safeRoomService.disconnect()
        activeSession = nil
        activeRoomToken = nil
        connectionState = .disconnected

        if let endingSession {
            // Mark session as completed
            if let index = sessions.firstIndex(where: { $0.id == endingSession.id }) {
                let updated = CoachingSession(
                    id: endingSession.id,
                    coachAlias: endingSession.coachAlias,
                    coachAvatarSeed: endingSession.coachAvatarSeed,
                    category: endingSession.category,
                    tier: endingSession.tier,
                    scheduledDate: endingSession.scheduledDate,
                    timeSlot: endingSession.timeSlot,
                    timeZoneIdentifier: endingSession.timeZoneIdentifier,
                    status: .completed,
                    hasReflection: endingSession.hasReflection,
                    reflectionId: endingSession.reflectionId
                )
                sessions[index] = updated
                triggerPostSessionReflection(for: updated)
            } else {
                triggerPostSessionReflection(for: endingSession)
            }

            // Schedule local/APNs notification trigger
            await notificationManager.scheduleLocalPostSessionPrompt(for: endingSession)
        }
    }

    /// Triggers the post-session reflection presentation for `session`.
    public func triggerPostSessionReflection(for session: CoachingSession) {
        pendingReflectionSession = session
        showReflectionSheet = true
    }

    /// Dismisses the reflection sheet without completing.
    public func dismissReflection() {
        pendingReflectionSession = nil
        showReflectionSheet = false
    }

    /// Saves the reflection and updates the session reflection state.
    public func saveReflection(_ reflection: SessionReflection) async {
        do {
            try await reflectionService.saveReflection(reflection)

            // Submit public testimonial if provided
            if let testimonial = reflection.toCoachTestimonial(
                clientAlias: "Anonymous Client",
                category: .burnout,
                dateString: "Today"
            ) {
                try? await reflectionService.submitPublicTestimonial(testimonial, for: nil)
            }

            // Update matching session in sessions list
            if let index = sessions.firstIndex(where: { $0.id == reflection.sessionId }) {
                let current = sessions[index]
                let updated = CoachingSession(
                    id: current.id,
                    coachAlias: current.coachAlias,
                    coachAvatarSeed: current.coachAvatarSeed,
                    category: current.category,
                    tier: current.tier,
                    scheduledDate: current.scheduledDate,
                    timeSlot: current.timeSlot,
                    timeZoneIdentifier: current.timeZoneIdentifier,
                    status: .completed,
                    hasReflection: true,
                    reflectionId: reflection.id
                )
                sessions[index] = updated
            }

            reflectionSuccessMessage = "Thank you. Your reflection and testimonial have been saved."
            dismissReflection()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Handles an incoming APNs or in-app notification event.
    public func handleNotificationEvent(_ event: SessionNotificationEvent) {
        switch event {
        case .postSessionReflection(let sessionId, let coachAlias):
            if let session = sessions.first(where: { $0.id == sessionId }) {
                triggerPostSessionReflection(for: session)
            } else {
                // If not in memory, construct a proxy session
                let proxy = CoachingSession(
                    id: sessionId,
                    coachAlias: coachAlias,
                    coachAvatarSeed: coachAlias,
                    category: .burnout,
                    tier: .paid,
                    scheduledDate: currentDate,
                    timeSlot: "Completed",
                    timeZoneIdentifier: TimeZone.current.identifier,
                    status: .completed,
                    hasReflection: false
                )
                triggerPostSessionReflection(for: proxy)
            }
        case .safeRoomReady(let sessionId, _):
            if let session = sessions.first(where: { $0.id == sessionId }) {
                Task {
                    await enterSafeRoom(for: session)
                }
            }
        }
    }
}
