import Foundation

/// Central configuration for Anony API environments and network endpoints.
public enum APIConfig {
    /// Default production base URL.
    public static let defaultBaseURL = URL(string: "https://api.anony.app")!

    /// Current base URL for API requests.
    public static var currentBaseURL: URL = defaultBaseURL
}

/// Centralized API endpoint constants and path builders.
/// Referenced across network clients, repositories, and mock services.
public enum APIEndpoints {
    // MARK: - Auth & Identity
    public static let register = "/api/v1/auth/register"
    public static let login = "/api/v1/auth/login"
    public static let me = "/api/v1/auth/me"

    // MARK: - Coaches & Directory
    public static let coaches = "/api/v1/coaches"
    public static let favorites = "/api/v1/coaches/favorites"

    public static func coachDetails(id: UUID) -> String {
        "/api/v1/coaches/\(id.uuidString)"
    }

    public static func coachFavorite(id: UUID) -> String {
        "/api/v1/coaches/\(id.uuidString)/favorite"
    }

    public static func coachSlots(id: UUID) -> String {
        "/api/v1/coaches/\(id.uuidString)/slots"
    }

    // MARK: - Matching, Sessions & Bookings
    public static let blindMatch = "/api/v1/match/blind"
    public static let sessions = "/api/v1/sessions"
    public static let bookings = "/api/v1/bookings"

    public static func sessionDetails(id: UUID) -> String {
        "/api/v1/sessions/\(id.uuidString)"
    }

    // MARK: - URL Resolution Helper
    /// Resolves the absolute URL using the active APIConfig.currentBaseURL.
    public static func url(for endpointPath: String) -> URL {
        if let fullURL = URL(string: endpointPath, relativeTo: APIConfig.currentBaseURL)?.absoluteURL {
            return fullURL
        }
        return APIConfig.currentBaseURL.appendingPathComponent(endpointPath)
    }
}
