import Foundation
import Combine
#if canImport(UserNotifications)
import UserNotifications
#endif

/// Notification events routed to in-app views and coordinators.
public enum SessionNotificationEvent: Sendable, Equatable {
    case postSessionReflection(sessionId: UUID, coachAlias: String)
    case safeRoomReady(sessionId: UUID, coachAlias: String)
}

/// Protocol for push notifications and in-app session alerts.
@MainActor
public protocol NotificationManagerProtocol: AnyObject, Sendable {
    nonisolated func parseRemoteNotification(userInfo: [AnyHashable: Any]) -> SessionNotificationEvent?
    @discardableResult
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) -> SessionNotificationEvent?
    func requestAuthorization() async -> Bool
    func scheduleLocalPostSessionPrompt(for session: CoachingSession) async
}

/// Manager coordinating APNs push notification payloads, user permissions,
/// and routing in-app reflection prompts.
@MainActor
public final class NotificationManager: ObservableObject, NotificationManagerProtocol {
    public static let shared = NotificationManager()

    @Published public private(set) var latestEvent: SessionNotificationEvent? = nil
    @Published public private(set) var isAuthorized: Bool = false
    @Published public private(set) var scheduledPrompts: [UUID] = []

    nonisolated public init() {}

    /// Parses APNs remote notification user info payload into a typed `SessionNotificationEvent`.
    /// Expects `type` ("session_ended" or "safe_room_open"), `sessionId` (UUID string),
    /// and `coachAlias` (string).
    nonisolated public func parseRemoteNotification(userInfo: [AnyHashable: Any]) -> SessionNotificationEvent? {
        guard let typeString = userInfo["type"] as? String else {
            return nil
        }

        guard let sessionIdString = userInfo["sessionId"] as? String,
              let sessionId = UUID(uuidString: sessionIdString) else {
            return nil
        }

        let coachAlias = (userInfo["coachAlias"] as? String) ?? "Your Coach"

        switch typeString.lowercased() {
        case "session_ended", "post_session_reflection":
            return .postSessionReflection(sessionId: sessionId, coachAlias: coachAlias)
        case "safe_room_open", "safe_room_ready":
            return .safeRoomReady(sessionId: sessionId, coachAlias: coachAlias)
        default:
            return nil
        }
    }

    /// Handles an incoming APNs remote notification and publishes it to observers.
    @discardableResult
    public func handleRemoteNotification(userInfo: [AnyHashable: Any]) -> SessionNotificationEvent? {
        guard let event = parseRemoteNotification(userInfo: userInfo) else {
            return nil
        }

        self.latestEvent = event
        return event
    }

    /// Requests push notification authorization via `UNUserNotificationCenter` if available.
    public func requestAuthorization() async -> Bool {
        #if canImport(UserNotifications)
        guard let bundleId = Bundle.main.bundleIdentifier,
              !bundleId.contains("xctest"),
              !bundleId.contains("Testing") else {
            self.isAuthorized = true
            return true
        }
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            self.isAuthorized = granted
            return granted
        } catch {
            self.isAuthorized = false
            return false
        }
        #else
        self.isAuthorized = true
        return true
        #endif
    }

    /// Schedules an in-app or local notification prompt once an anonymous coaching session concludes.
    public func scheduleLocalPostSessionPrompt(for session: CoachingSession) async {
        scheduledPrompts.append(session.id)
        #if canImport(UserNotifications)
        guard let bundleId = Bundle.main.bundleIdentifier,
              !bundleId.contains("xctest"),
              !bundleId.contains("Testing") else {
            return
        }
        do {
            let content = UNMutableNotificationContent()
            content.title = "Session Completed"
            content.body = "Single-tap to reflect and rate your session with \(session.coachAlias)."
            content.sound = .default
            content.userInfo = [
                "type": "session_ended",
                "sessionId": session.id.uuidString,
                "coachAlias": session.coachAlias
            ]

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
            let request = UNNotificationRequest(
                identifier: "session-reflection-\(session.id.uuidString)",
                content: content,
                trigger: trigger
            )

            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Silently ignore notification registration failures in restricted environments
        }
        #endif
    }

    /// Clears the latest event once processed.
    public func clearLatestEvent() {
        self.latestEvent = nil
    }
}
