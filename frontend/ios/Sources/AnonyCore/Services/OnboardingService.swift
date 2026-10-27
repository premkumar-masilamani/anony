import Foundation

/// Protocol governing client onboarding state and preference persistence.
public protocol OnboardingServiceProtocol: AnyObject, Sendable {
    func hasCompletedOnboarding() -> Bool
    func setOnboardingCompleted(_ completed: Bool)
    func savePreferences(_ preferences: OnboardingPreferences)
    func getPreferences() -> OnboardingPreferences?
    func reset()
}

/// Persistent onboarding service backed by standard iOS UserDefaults.
public final class UserDefaultsOnboardingService: OnboardingServiceProtocol, @unchecked Sendable {
    public static let shared = UserDefaultsOnboardingService()

    private let userDefaults: UserDefaults
    private let hasCompletedKey = "anony.onboarding.hasCompleted"
    private let preferencesKey = "anony.onboarding.preferences"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func hasCompletedOnboarding() -> Bool {
        userDefaults.bool(forKey: hasCompletedKey)
    }

    public func setOnboardingCompleted(_ completed: Bool) {
        userDefaults.set(completed, forKey: hasCompletedKey)
    }

    public func savePreferences(_ preferences: OnboardingPreferences) {
        do {
            let data = try JSONEncoder().encode(preferences)
            userDefaults.set(data, forKey: preferencesKey)
            setOnboardingCompleted(true)
        } catch {
            assertionFailure("Failed to encode onboarding preferences: \(error)")
        }
    }

    public func getPreferences() -> OnboardingPreferences? {
        guard let data = userDefaults.data(forKey: preferencesKey) else {
            return nil
        }
        return try? JSONDecoder().decode(OnboardingPreferences.self, from: data)
    }

    public func reset() {
        userDefaults.removeObject(forKey: hasCompletedKey)
        userDefaults.removeObject(forKey: preferencesKey)
    }
}

/// In-memory mock onboarding service for unit testing and SwiftUI previews.
public final class MockOnboardingService: OnboardingServiceProtocol, @unchecked Sendable {
    private var completed: Bool
    private var preferences: OnboardingPreferences?

    public init(completed: Bool = false, preferences: OnboardingPreferences? = nil) {
        self.completed = completed
        self.preferences = preferences
    }

    public func hasCompletedOnboarding() -> Bool {
        completed
    }

    public func setOnboardingCompleted(_ completed: Bool) {
        self.completed = completed
    }

    public func savePreferences(_ preferences: OnboardingPreferences) {
        self.preferences = preferences
        self.completed = true
    }

    public func getPreferences() -> OnboardingPreferences? {
        preferences
    }

    public func reset() {
        completed = false
        preferences = nil
    }
}
