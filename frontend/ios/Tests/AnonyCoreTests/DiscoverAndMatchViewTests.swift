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

    @Test("DiscoverAndMatchViewModel performs blind match")
    @MainActor
    func testBlindMatchInViewModel() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)
        let viewModel = CoachDiscoveryViewModel(coachService: service)

        viewModel.blindMatchPrompt = "Struggling with burnout and boundaries at my tech company"
        await viewModel.submitBlindMatch()

        #expect(viewModel.blindMatchResult != nil)
        #expect(viewModel.blindMatchResult?.tier == .free)
        #expect(viewModel.isBlindMatchActive == false)
    }
}
