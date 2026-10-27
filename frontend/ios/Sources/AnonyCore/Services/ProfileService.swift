import Foundation

/// Protocol governing client profile retrieval, persistence, and privacy mode updates.
public protocol ProfileServiceProtocol: AnyObject, Sendable {
    func getProfile() -> ClientProfile
    func saveProfile(_ profile: ClientProfile)
    func updateProfile(_ profile: ClientProfile) async throws -> ClientProfile
    func updatePrivacyMode(isAnonymous: Bool) async throws -> Bool
    func reset()
}

/// Persistent profile service backed by iOS UserDefaults and synced with IdentityService Keychain.
public final class UserDefaultsProfileService: ProfileServiceProtocol, @unchecked Sendable {
    public static let shared = UserDefaultsProfileService()

    private let userDefaults: UserDefaults
    private let identityService: IdentityService
    private let storageKey = "anony.client.profile"
    private let lock = NSLock()

    public init(
        userDefaults: UserDefaults = .standard,
        identityService: IdentityService = .shared
    ) {
        self.userDefaults = userDefaults
        self.identityService = identityService
    }

    public func getProfile() -> ClientProfile {
        lock.lock()
        defer { lock.unlock() }

        if let data = userDefaults.data(forKey: storageKey),
           let profile = try? JSONDecoder().decode(ClientProfile.self, from: data) {
            return profile
        }

        // Initialize default profile pre-filled with Keychain identity credentials if present
        let alias = identityService.fetchAlias() ?? ClientProfile.generateTranquilAlias()
        let email = identityService.fetchEmail() ?? ""
        let defaultProfile = ClientProfile(alias: alias, email: email, isAnonymousMode: true)

        if let encoded = try? JSONEncoder().encode(defaultProfile) {
            userDefaults.set(encoded, forKey: storageKey)
        }
        return defaultProfile
    }

    public func saveProfile(_ profile: ClientProfile) {
        lock.lock()
        defer { lock.unlock() }

        if let encoded = try? JSONEncoder().encode(profile) {
            userDefaults.set(encoded, forKey: storageKey)
        }

        // Sync alias and email back to Keychain
        if !profile.alias.isEmpty {
            _ = identityService.saveAlias(profile.alias)
        }
        if !profile.email.isEmpty {
            _ = identityService.saveEmail(profile.email)
        }
    }

    public func updateProfile(_ profile: ClientProfile) async throws -> ClientProfile {
        // Reference endpoint path in accordance with project architecture
        _ = APIEndpoints.clientProfile

        // Simulate network latency for API update
        try await Task.sleep(nanoseconds: 40_000_000)

        saveProfile(profile)
        return profile
    }

    public func updatePrivacyMode(isAnonymous: Bool) async throws -> Bool {
        // Reference endpoint path in accordance with project architecture
        _ = APIEndpoints.clientPrivacyMode

        // Simulate network latency for API update
        try await Task.sleep(nanoseconds: 30_000_000)

        var profile = getProfile()
        profile.isAnonymousMode = isAnonymous
        saveProfile(profile)
        return isAnonymous
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.removeObject(forKey: storageKey)
    }
}

/// In-memory mock profile service for unit testing and SwiftUI previews.
public final class MockProfileService: ProfileServiceProtocol, @unchecked Sendable {
    private var profile: ClientProfile
    private let lock = NSLock()

    public init(initialProfile: ClientProfile? = nil) {
        self.profile = initialProfile ?? ClientProfile(
            alias: "TranquilOwl42",
            fullName: "Alex Morgan",
            email: "alex@example.com",
            isAnonymousMode: true
        )
    }

    public func getProfile() -> ClientProfile {
        lock.lock()
        defer { lock.unlock() }
        return profile
    }

    public func saveProfile(_ profile: ClientProfile) {
        lock.lock()
        defer { lock.unlock() }
        self.profile = profile
    }

    public func updateProfile(_ profile: ClientProfile) async throws -> ClientProfile {
        _ = APIEndpoints.clientProfile
        saveProfile(profile)
        return profile
    }

    public func updatePrivacyMode(isAnonymous: Bool) async throws -> Bool {
        _ = APIEndpoints.clientPrivacyMode
        var updated = getProfile()
        updated.isAnonymousMode = isAnonymous
        saveProfile(updated)
        return isAnonymous
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        self.profile = ClientProfile()
    }
}
