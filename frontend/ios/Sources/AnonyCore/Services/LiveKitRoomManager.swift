import Foundation

/// Token and room metadata returned when joining an encrypted WebRTC Safe Room.
public struct SafeRoomConnectionToken: Codable, Sendable, Equatable {
    public let sessionId: UUID
    public let roomName: String
    public let token: String
    public let serverURL: String
    public let endpoint: String

    public init(
        sessionId: UUID,
        roomName: String,
        token: String,
        serverURL: String,
        endpoint: String
    ) {
        self.sessionId = sessionId
        self.roomName = roomName
        self.token = token
        self.serverURL = serverURL
        self.endpoint = endpoint
    }
}

/// Lifecycle state of the client's WebRTC Safe Room connection.
public enum SafeRoomConnectionState: Sendable, Equatable {
    case disconnected
    case connecting(sessionId: UUID)
    case connected(SafeRoomConnectionToken)
    case failed(String)
}

/// Errors thrown during WebRTC Safe Room connection initialization.
public enum SafeRoomServiceError: Error, LocalizedError, Sendable, Equatable {
    case safeRoomNotOpenYet
    case invalidSessionState
    case connectionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .safeRoomNotOpenYet:
            return "Safe Room opens 10 minutes before your scheduled session."
        case .invalidSessionState:
            return "This session is no longer active."
        case .connectionFailed(let reason):
            return reason
        }
    }
}

/// Protocol abstracting WebRTC Safe Room join-token negotiation and room connection.
public protocol SafeRoomServiceProtocol: Sendable {
    @MainActor
    func connectToSafeRoom(for session: CoachingSession, at referenceDate: Date) async throws -> SafeRoomConnectionToken

    @MainActor
    func disconnect() async
}

/// Default WebRTC Safe Room manager coordinating join-token acquisition and room connection state.
@MainActor
public final class LiveKitRoomManager: ObservableObject, SafeRoomServiceProtocol {
    @Published public private(set) var connectionState: SafeRoomConnectionState = .disconnected
    @Published public private(set) var activeToken: SafeRoomConnectionToken? = nil
    @Published public private(set) var connectCallCount: Int = 0

    public var shouldSimulateFailure: Bool = false

    public init() {}

    public func connectToSafeRoom(
        for session: CoachingSession,
        at referenceDate: Date = Date()
    ) async throws -> SafeRoomConnectionToken {
        guard session.status != .completed && session.status != .cancelled else {
            throw SafeRoomServiceError.invalidSessionState
        }

        guard session.canEnterSafeRoom(at: referenceDate) else {
            throw SafeRoomServiceError.safeRoomNotOpenYet
        }

        connectCallCount += 1
        connectionState = .connecting(sessionId: session.id)

        if shouldSimulateFailure {
            let reason = "Unable to establish encrypted WebRTC Safe Room connection."
            connectionState = .failed(reason)
            throw SafeRoomServiceError.connectionFailed(reason)
        }

        let endpointPath = APIEndpoints.sessionJoinToken(id: session.id)
        let resolvedURL = APIEndpoints.url(for: endpointPath)
        let token = SafeRoomConnectionToken(
            sessionId: session.id,
            roomName: "safe-room-\(session.id.uuidString.lowercased())",
            token: "lk-jwt-\(session.id.uuidString.prefix(8).lowercased())",
            serverURL: resolvedURL.deletingLastPathComponent().absoluteString,
            endpoint: endpointPath
        )

        activeToken = token
        connectionState = .connected(token)
        return token
    }

    public func disconnect() async {
        activeToken = nil
        connectionState = .disconnected
    }
}
