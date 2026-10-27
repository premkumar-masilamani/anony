import Foundation
import Testing
@testable import AnonyCore

@Suite("DiscoverAndMatchViewTests", .serialized)
struct DiscoverAndMatchViewTests {

    @Test("DiscoverAndMatchView initializes with default state and mock service")
    @MainActor
    func testInitialization() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)
        let view = DiscoverAndMatchView(coachService: service)

        #expect(view.coaches.count >= 6)
        #expect(view.selectedCategory == nil)
        #expect(view.selectedTier == nil)
    }

    @Test("DiscoverAndMatchViewModel loads coaches and filters in real time")
    @MainActor
    func testViewModelFiltering() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)
        let viewModel = CoachDiscoveryViewModel(coachService: service)

        await viewModel.loadCoaches()
        let allCount = viewModel.filteredCoaches.count
        #expect(allCount >= 6)

        // Filter by Topic
        viewModel.selectedTopic = .relationship
        #expect(viewModel.filteredCoaches.allSatisfy { $0.topic == .relationship })

        viewModel.selectedTopic = nil

        // Filter by ICF Level
        viewModel.selectedICFLevel = .mcc
        #expect(viewModel.filteredCoaches.allSatisfy { $0.icfLevel == .mcc })

        viewModel.selectedICFLevel = nil

        // Filter by Tier
        viewModel.selectedTier = .free
        #expect(viewModel.filteredCoaches.allSatisfy { $0.tier == .free })

        viewModel.selectedTier = .paid
        #expect(viewModel.filteredCoaches.allSatisfy { $0.tier == .paid })

        viewModel.selectedTier = nil

        // Filter by Language
        viewModel.selectedLanguage = "Spanish"
        #expect(viewModel.filteredCoaches.allSatisfy { $0.languages.contains("Spanish") })
    }

    @Test("DiscoverAndMatchViewModel toggles and persists favorites in real time")
    @MainActor
    func testFavoriteToggleInViewModel() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)
        let viewModel = CoachDiscoveryViewModel(coachService: service)

        await viewModel.loadCoaches()
        guard let firstCoach = viewModel.filteredCoaches.first else {
            Issue.record("Expected coaches in view model")
            return
        }

        #expect(viewModel.isFavorite(firstCoach.id) == false)

        await viewModel.toggleFavorite(for: firstCoach.id)
        #expect(viewModel.isFavorite(firstCoach.id) == true)
        #expect(storage.getFavorites().contains(firstCoach.id))

        await viewModel.toggleFavorite(for: firstCoach.id)
        #expect(viewModel.isFavorite(firstCoach.id) == false)
        #expect(!storage.getFavorites().contains(firstCoach.id))
    }

    @Test("DiscoverAndMatchViewModel performs blind match and schedules session")
    @MainActor
    func testBlindMatchInViewModel() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)
        let viewModel = CoachDiscoveryViewModel(coachService: service)

        viewModel.selectedTimeWindow = .morning
        viewModel.blindMatchPrompt = "Struggling with burnout and boundaries at my tech company"
        await viewModel.submitBlindMatch()

        #expect(viewModel.blindMatchResult != nil)
        #expect(viewModel.blindMatchResult?.tier == .free)
        #expect(viewModel.scheduledSession != nil)
        #expect(viewModel.scheduledSession?.status == "CONFIRMED")
        #expect(viewModel.scheduledSession?.isProBono == true)
        #expect(viewModel.isBlindMatchActive == false)

        viewModel.resetBlindMatch()
        #expect(viewModel.blindMatchPrompt.isEmpty)
        #expect(viewModel.scheduledSession == nil)
    }

    @Test("DiscoverAndMatchViewModel enforces 14-day cooldown for client profile")
    @MainActor
    func testBlindMatchCooldownEnforcement() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)
        let viewModel = CoachDiscoveryViewModel(coachService: service)

        let profile = ClientProfile(
            alias: "CooldownClient",
            freeSessionsUsed: 2,
            lastFreeSessionDate: Date().addingTimeInterval(-5 * 86400) // 5 days ago
        )

        viewModel.blindMatchPrompt = "Need pro bono session"
        await viewModel.submitBlindMatch(profile: profile)

        #expect(viewModel.isCooldownActive == true)
        #expect(viewModel.cooldownDaysRemaining == 9)
        #expect(viewModel.scheduledSession == nil)
        #expect(viewModel.blindMatchError != nil)
    }

    @Test("DiscoverAndMatchViewModel enforces 6-session lifetime cap for client profile")
    @MainActor
    func testBlindMatchLifetimeCapEnforcement() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)
        let viewModel = CoachDiscoveryViewModel(coachService: service)

        let profile = ClientProfile(
            alias: "CappedClient",
            freeSessionsUsed: 6
        )

        viewModel.blindMatchPrompt = "Need session"
        await viewModel.submitBlindMatch(profile: profile)

        #expect(viewModel.isLifetimeCapReached == true)
        #expect(viewModel.scheduledSession == nil)
        #expect(viewModel.blindMatchError != nil)
    }

    @Test("DiscoverAndMatchView instantiates cleanly in both anonymous and regular modes")
    @MainActor
    func testDualModeInstantiation() {
        let service = MockCoachService()
        let anonView = DiscoverAndMatchView(coachService: service, isAnonymousMode: true)
        let regularView = DiscoverAndMatchView(coachService: service, isAnonymousMode: false)

        #expect(anonView.isAnonymousMode == true)
        #expect(regularView.isAnonymousMode == false)
    }
}
