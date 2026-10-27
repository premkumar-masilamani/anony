import Foundation
import Testing
@testable import AnonyCore

@Suite("CoachServiceProfileTests", .serialized)
struct CoachServiceProfileTests {

    @Test("fetchCoachDetails returns full profile or throws coachNotFound")
    func testFetchCoachDetails() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)

        let all = try await service.fetchCoaches(filter: CoachFilter())
        let firstCoach = all[0]

        let details = try await service.fetchCoachDetails(coachId: firstCoach.id)
        #expect(details.id == firstCoach.id)
        #expect(details.alias == firstCoach.alias)
        #expect(!details.bio.isEmpty)
        #expect(!details.philosophy.isEmpty)

        // Non-existent coach throws
        let fakeId = UUID()
        await #expect(throws: CoachServiceError.coachNotFound) {
            _ = try await service.fetchCoachDetails(coachId: fakeId)
        }
    }

    @Test("fetchAvailableSlots returns available unbooked slots for a given day")
    func testFetchAvailableSlots() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)

        let all = try await service.fetchCoaches(filter: CoachFilter())
        let coach = all[0]

        let today = Date()
        let slots = try await service.fetchAvailableSlots(coachId: coach.id, for: today)
        #expect(!slots.isEmpty)
        for slot in slots {
            #expect(slot.isBooked == false)
            #expect(slot.isSameDay(as: today, in: .current))
        }
    }

    @Test("bookSession reserves slot and marks it booked preventing double booking")
    func testBookSession() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)

        let all = try await service.fetchCoaches(filter: CoachFilter())
        let coach = all[0]
        let today = Date()

        let initialSlots = try await service.fetchAvailableSlots(coachId: coach.id, for: today)
        guard let slotToBook = initialSlots.first else {
            Issue.record("Expected available slot for today")
            return
        }

        let session = try await service.bookSession(
            coachId: coach.id,
            slot: slotToBook,
            clientAlias: "TranquilPine42"
        )

        #expect(session.coachAlias == coach.alias)
        #expect(session.status == .confirmed)
        #expect(session.category == coach.specialty)
        #expect(session.tier == coach.tier)

        // Verify slot is now booked and no longer returned in available slots
        let remainingSlots = try await service.fetchAvailableSlots(coachId: coach.id, for: today)
        #expect(!remainingSlots.contains(where: { $0.id == slotToBook.id }))

        // Attempting to book the same slot again fails with slotUnavailable
        await #expect(throws: CoachServiceError.slotUnavailable) {
            _ = try await service.bookSession(
                coachId: coach.id,
                slot: slotToBook,
                clientAlias: "SecondClient"
            )
        }
    }
}
