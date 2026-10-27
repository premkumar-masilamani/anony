import Foundation
import Testing
@testable import AnonyCore

@Suite("CoachServiceTests", .serialized)
struct CoachServiceTests {

    @Test("MockCoachService returns all coaches when no filter applied")
    func testFetchAllCoaches() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)

        let coaches = try await service.fetchCoaches(filter: CoachFilter())
        #expect(coaches.count >= 6)
    }

    @Test("MockCoachService filters coaches by Topic in real time")
    func testFilterByTopic() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)

        var filter = CoachFilter()
        filter.topic = .careerBurnout

        let coaches = try await service.fetchCoaches(filter: filter)
        #expect(!coaches.isEmpty)
        for coach in coaches {
            #expect(coach.topic == .careerBurnout)
        }
    }

    @Test("MockCoachService filters coaches by ICF level in real time")
    func testFilterByICFLevel() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)

        var filter = CoachFilter()
        filter.icfLevel = .mcc

        let coaches = try await service.fetchCoaches(filter: filter)
        #expect(!coaches.isEmpty)
        for coach in coaches {
            #expect(coach.icfLevel == .mcc)
        }
    }

    @Test("MockCoachService filters coaches by Free vs Paid in real time")
    func testFilterByPricingTier() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)

        var freeFilter = CoachFilter()
        freeFilter.tier = .free
        let freeCoaches = try await service.fetchCoaches(filter: freeFilter)
        #expect(!freeCoaches.isEmpty)
        for coach in freeCoaches {
            #expect(coach.tier == .free)
            #expect(coach.hourlyRate == 0)
        }

        var paidFilter = CoachFilter()
        paidFilter.tier = .paid
        let paidCoaches = try await service.fetchCoaches(filter: paidFilter)
        #expect(!paidCoaches.isEmpty)
        for coach in paidCoaches {
            #expect(coach.tier == .paid)
            #expect(coach.hourlyRate > 0)
        }
    }

    @Test("MockCoachService filters coaches by Language in real time")
    func testFilterByLanguage() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)

        var filter = CoachFilter()
        filter.language = "Spanish"

        let coaches = try await service.fetchCoaches(filter: filter)
        #expect(!coaches.isEmpty)
        for coach in coaches {
            #expect(coach.languages.contains("Spanish"))
        }
    }

    @Test("MockCoachService toggles and persists favorites")
    func testFavoritePersistence() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)

        let coaches = try await service.fetchCoaches(filter: CoachFilter())
        let targetCoach = coaches[0]

        #expect(service.isFavorite(coachId: targetCoach.id) == false)

        let isFavAfterToggle = try await service.toggleFavorite(coachId: targetCoach.id)
        #expect(isFavAfterToggle == true)
        #expect(service.isFavorite(coachId: targetCoach.id) == true)
        #expect(storage.getFavorites().contains(targetCoach.id))

        let isFavAfterSecondToggle = try await service.toggleFavorite(coachId: targetCoach.id)
        #expect(isFavAfterSecondToggle == false)
        #expect(service.isFavorite(coachId: targetCoach.id) == false)
        #expect(!storage.getFavorites().contains(targetCoach.id))
    }

    @Test("MockCoachService performs blind semantic match prompt")
    func testBlindMatchPrompt() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)

        let matchedCoach = try await service.performBlindMatch(prompt: "I feel completely overwhelmed by executive expectations and burn out daily")
        #expect(matchedCoach.tier == .free)
        #expect(matchedCoach.topic == .careerBurnout || matchedCoach.topic == .executive)
    }
}
