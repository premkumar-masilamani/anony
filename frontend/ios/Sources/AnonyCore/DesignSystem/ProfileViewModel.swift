import Foundation
import SwiftUI
import Combine

/// Real-time View Model driving client profile updates and anonymity mode toggling.
@MainActor
public final class ProfileViewModel: ObservableObject {
    @Published public var alias: String = ""
    @Published public var fullName: String = ""
    @Published public var email: String = ""
    @Published public var isAnonymousMode: Bool = true
    @Published public var preferredLanguage: String = "English"
    @Published public var timeZoneIdentifier: String = TimeZone.current.identifier
    @Published public var primaryFocus: StruggleCategory = .burnout
    @Published public var freeSessionsUsed: Int = 0
    @Published public var maxFreeSessions: Int = 6
    @Published public var lastFreeSessionDate: Date? = nil

    @Published public var isSaving: Bool = false
    @Published public var saveSuccessMessage: String? = nil
    @Published public var errorMessage: String? = nil

    public let profileService: ProfileServiceProtocol
    public var onProfileUpdated: ((ClientProfile) -> Void)?

    public init(
        profileService: ProfileServiceProtocol = UserDefaultsProfileService.shared,
        onProfileUpdated: ((ClientProfile) -> Void)? = nil
    ) {
        self.profileService = profileService
        self.onProfileUpdated = onProfileUpdated
        loadProfile()
    }

    public func loadProfile() {
        let profile = profileService.getProfile()
        self.alias = profile.alias
        self.fullName = profile.fullName
        self.email = profile.email
        self.isAnonymousMode = profile.isAnonymousMode
        self.preferredLanguage = profile.preferredLanguage
        self.timeZoneIdentifier = profile.timeZoneIdentifier
        self.primaryFocus = profile.primaryFocus
        self.freeSessionsUsed = profile.freeSessionsUsed
        self.maxFreeSessions = profile.maxFreeSessions
        self.lastFreeSessionDate = profile.lastFreeSessionDate
    }

    public func toggleAnonymity() async {
        let newMode = !isAnonymousMode
        isSaving = true
        errorMessage = nil
        do {
            let updated = try await profileService.updatePrivacyMode(isAnonymous: newMode)
            self.isAnonymousMode = updated
            saveSuccessMessage = updated ? "Anonymous Blind Mode Enabled" : "Regular Directory Mode Enabled"
            notifyUpdate()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    public func regenerateAlias() {
        self.alias = ClientProfile.generateTranquilAlias()
    }

    public func saveProfile() async {
        isSaving = true
        errorMessage = nil
        saveSuccessMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedEmail.isEmpty && (!trimmedEmail.contains("@") || !trimmedEmail.contains(".")) {
            self.errorMessage = "Please enter a valid email address."
            isSaving = false
            return
        }

        let updatedProfile = ClientProfile(
            alias: alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ClientProfile.generateTranquilAlias() : alias,
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: trimmedEmail,
            isAnonymousMode: isAnonymousMode,
            preferredLanguage: preferredLanguage,
            timeZoneIdentifier: timeZoneIdentifier,
            primaryFocus: primaryFocus,
            freeSessionsUsed: freeSessionsUsed,
            maxFreeSessions: maxFreeSessions,
            lastFreeSessionDate: lastFreeSessionDate
        )

        do {
            let saved = try await profileService.updateProfile(updatedProfile)
            self.alias = saved.alias
            self.saveSuccessMessage = "Profile updated successfully."
            notifyUpdate()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func notifyUpdate() {
        let current = profileService.getProfile()
        onProfileUpdated?(current)
    }

    public var isCooldownActive: Bool {
        guard let lastDate = lastFreeSessionDate else { return false }
        return Date().timeIntervalSince(lastDate) < 14 * 86400
    }

    public var daysUntilNextFreeSession: Int {
        guard let lastDate = lastFreeSessionDate else { return 0 }
        let remaining = (14 * 86400) - Date().timeIntervalSince(lastDate)
        if remaining <= 0 { return 0 }
        return Int(ceil(remaining / 86400))
    }
}
