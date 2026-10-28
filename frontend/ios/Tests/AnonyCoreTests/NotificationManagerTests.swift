import Foundation
import Testing
@testable import AnonyCore

@Suite("NotificationManager & APNs Tests", .serialized)
@MainActor
struct NotificationManagerTests {

    @Test("Parse valid APNs session_ended push payload")
    func testParseValidSessionEndedPayload() {
        let sessionId = UUID()
        let payload: [AnyHashable: Any] = [
            "aps": [
                "alert": [
                    "title": "Session Completed",
                    "body": "Your session with Coach Elena has ended. Reflect and rate."
                ],
                "sound": "default",
                "badge": 1
            ],
            "type": "session_ended",
            "sessionId": sessionId.uuidString,
            "coachAlias": "Coach Elena"
        ]

        let manager = NotificationManager()
        let event = manager.parseRemoteNotification(userInfo: payload)

        #expect(event != nil)
        switch event {
        case .postSessionReflection(let parsedSessionId, let coachAlias):
            #expect(parsedSessionId == sessionId)
            #expect(coachAlias == "Coach Elena")
        default:
            Issue.record("Expected .postSessionReflection event")
        }
    }

    @Test("Parse APNs safe_room_open push payload")
    func testParseSafeRoomOpenPayload() {
        let sessionId = UUID()
        let payload: [AnyHashable: Any] = [
            "aps": [
                "alert": [
                    "title": "Safe Room Open",
                    "body": "Safe Room for Coach Marcus is now open."
                ]
            ],
            "type": "safe_room_open",
            "sessionId": sessionId.uuidString,
            "coachAlias": "Coach Marcus"
        ]

        let manager = NotificationManager()
        let event = manager.parseRemoteNotification(userInfo: payload)

        #expect(event != nil)
        switch event {
        case .safeRoomReady(let parsedSessionId, let coachAlias):
            #expect(parsedSessionId == sessionId)
            #expect(coachAlias == "Coach Marcus")
        default:
            Issue.record("Expected .safeRoomReady event")
        }
    }

    @Test("Parse invalid or missing APNs payload returns nil")
    func testParseInvalidPayload() {
        let manager = NotificationManager()

        let emptyPayload: [AnyHashable: Any] = [:]
        #expect(manager.parseRemoteNotification(userInfo: emptyPayload) == nil)

        let invalidTypePayload: [AnyHashable: Any] = [
            "type": "unknown_event",
            "sessionId": UUID().uuidString
        ]
        #expect(manager.parseRemoteNotification(userInfo: invalidTypePayload) == nil)

        let missingSessionIdPayload: [AnyHashable: Any] = [
            "type": "session_ended",
            "coachAlias": "Coach Elena"
        ]
        #expect(manager.parseRemoteNotification(userInfo: missingSessionIdPayload) == nil)
    }

    @Test("NotificationManager triggers event publisher when handling push notification")
    func testHandlePushNotificationPublishesEvent() async {
        let manager = NotificationManager()
        let sessionId = UUID()
        let payload: [AnyHashable: Any] = [
            "type": "session_ended",
            "sessionId": sessionId.uuidString,
            "coachAlias": "Coach Elena"
        ]

        let event = manager.handleRemoteNotification(userInfo: payload)
        #expect(event == .postSessionReflection(sessionId: sessionId, coachAlias: "Coach Elena"))
        #expect(manager.latestEvent == event)
    }
}
