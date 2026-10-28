import Foundation
import Testing
@testable import AnonyCore

@Suite("ClientProfileTests", .serialized)
struct ClientProfileTests {

    @Test("ClientProfile initializes with sensible defaults and conforms to Codable")
    func testProfileDefaultsAndCodable() throws {
        let profile = ClientProfile(
            alias: "TranquilOwl42",
            fullName: "Alex Morgan",
            email: "alex@example.com",
            isAnonymousMode: true,
            preferredLanguage: "English",
            timeZoneIdentifier: "America/New_York",
            primaryFocus: .burnout
        )

        #expect(profile.alias == "TranquilOwl42")
        #expect(profile.fullName == "Alex Morgan")
        #expect(profile.email == "alex@example.com")
        #expect(profile.isAnonymousMode == true)
        #expect(profile.freeSessionsUsed == 0)
        #expect(profile.maxFreeSessions == 6)
        #expect(profile.isCooldownActive() == false)

        let encoded = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(ClientProfile.self, from: encoded)
        #expect(decoded == profile)
    }

    @Test("ClientProfile 14-day cooldown calculation")
    func testCooldownCalculation() {
        let now = Date()
        var profile = ClientProfile(
            alias: "SereneBreeze10",
            email: "test@example.com",
            freeSessionsUsed: 2,
            lastFreeSessionDate: now.addingTimeInterval(-5 * 86400) // 5 days ago
        )

        #expect(profile.isCooldownActive(now: now) == true)
        #expect(profile.daysUntilNextFreeSession(now: now) == 9)

        // Session was 15 days ago -> cooldown expired
        profile.lastFreeSessionDate = now.addingTimeInterval(-15 * 86400)
        #expect(profile.isCooldownActive(now: now) == false)
        #expect(profile.daysUntilNextFreeSession(now: now) == 0)
    }

    @Test("ClientProfile 6-session lifetime cap enforcement")
    func testLifetimeCap() {
        var profile = ClientProfile(
            alias: "CalmPine12",
            email: "cap@example.com",
            freeSessionsUsed: 6
        )

        #expect(profile.hasReachedLifetimeCap == true)
        #expect(profile.canBookFreeSession() == false)

        profile.freeSessionsUsed = 3
        #expect(profile.hasReachedLifetimeCap == false)
    }

    @Test("ClientProfile procedural alias generator generates tranquil pseudonyms")
    func testProceduralAliasGenerator() {
        for _ in 0..<25 {
            let generatedAlias = ClientProfile.generateTranquilAlias()
            let parts = generatedAlias.split(separator: " ").map(String.init)
            #expect(parts.count == 2)
            #expect(ClientProfile.adjectives.contains(parts[0]))
            #expect(ClientProfile.nouns.contains(parts[1]))

            let avatarParams = AvatarCircleView.ProceduralParameters.generate(from: generatedAlias)
            #expect(AvatarCircleView.ProceduralParameters.curatedSymbols.contains(avatarParams.symbolName))
        }
    }

    @Test("MockProfileService saves and retrieves profile and syncs privacy mode")
    func testMockProfileService() async throws {
        let service = MockProfileService()
        var profile = service.getProfile()

        #expect(profile.isAnonymousMode == true)

        let isNowAnonymous = try await service.updatePrivacyMode(isAnonymous: false)
        #expect(isNowAnonymous == false)
        #expect(service.getProfile().isAnonymousMode == false)

        profile.fullName = "Taylor Jordan"
        profile.alias = "GentleStone88"
        _ = try await service.updateProfile(profile)

        let updated = service.getProfile()
        #expect(updated.fullName == "Taylor Jordan")
        #expect(updated.alias == "GentleStone88")
    }

    @Test("ProfileViewModel updates fields and toggles anonymity")
    @MainActor
    func testProfileViewModel() async throws {
        let service = MockProfileService()
        let viewModel = ProfileViewModel(profileService: service)

        #expect(viewModel.isAnonymousMode == true)

        // Toggle anonymity
        await viewModel.toggleAnonymity()
        #expect(viewModel.isAnonymousMode == false)
        #expect(service.getProfile().isAnonymousMode == false)

        // Update personal information
        viewModel.alias = "QuietRiver99"
        viewModel.fullName = "Morgan Reed"
        viewModel.preferredLanguage = "Spanish"
        viewModel.primaryFocus = .career

        await viewModel.saveProfile()
        #expect(viewModel.saveSuccessMessage != nil)

        let saved = service.getProfile()
        #expect(saved.alias == "QuietRiver99")
        #expect(saved.fullName == "Morgan Reed")
        #expect(saved.preferredLanguage == "Spanish")
        #expect(saved.primaryFocus == .career)
    }

    @Test("ProfileViewModel rejects invalid email formats")
    @MainActor
    func testProfileViewModelInvalidEmail() async throws {
        let service = MockProfileService()
        let viewModel = ProfileViewModel(profileService: service)

        viewModel.email = "invalidemailformat"
        await viewModel.saveProfile()

        #expect(viewModel.errorMessage == "Please enter a valid email address.")
        #expect(viewModel.saveSuccessMessage == nil)
    }

    @Test("MyProfileView instantiates cleanly on MainActor")
    @MainActor
    func testMyProfileViewInstantiation() {
        var didDismiss = false
        let service = MockProfileService()
        let view = MyProfileView(
            profileService: service,
            onProfileUpdated: { _ in },
            onDismiss: { didDismiss = true }
        )

        #expect(view.onDismiss != nil)
        view.onDismiss?()
        #expect(didDismiss == true)
    }
}
