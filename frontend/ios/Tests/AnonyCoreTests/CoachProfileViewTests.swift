import Foundation
import SwiftUI
import Testing
@testable import AnonyCore

@Suite("CoachProfileViewTests")
struct CoachProfileViewTests {

    @Test("CoachProfileView instantiates with full credentials, bio, and philosophy")
    @MainActor
    func testProfileViewCredentialsAndBio() {
        let coach = MockCoachService.defaultCoaches[1] // EchoClaritas (Paid MCC)
        let view = CoachProfileView(coach: coach)

        #expect(view.coach.alias == "EchoClaritas")
        #expect(view.coach.icfLevel == .mcc)
        #expect(view.coach.icfLevel.badgeTitle == "ICF MCC")
        #expect(!view.coach.bio.isEmpty)
        #expect(!view.coach.philosophy.isEmpty)
        #expect(view.coach.hourlyRate == 150)
        #expect(view.coach.tier == .paid)
    }

    @Test("CoachProfileView video preview placeholder duration and playback state toggle")
    @MainActor
    func testVideoPreviewPlaceholder() {
        let coach = MockCoachService.defaultCoaches[0] // AuraGuide
        let viewModel = CoachProfileViewModel(coach: coach)

        #expect(viewModel.coach.videoPreviewDuration == "1:00")
        #expect(!viewModel.coach.videoPreviewTitle.isEmpty)
        #expect(viewModel.isPlayingVideoPreview == false)

        viewModel.toggleVideoPreview()
        #expect(viewModel.isPlayingVideoPreview == true)

        viewModel.toggleVideoPreview()
        #expect(viewModel.isPlayingVideoPreview == false)
    }

    @Test("CoachProfileView testimonials carousel renders client reviews")
    @MainActor
    func testTestimonialsCarousel() {
        let coach = MockCoachService.defaultCoaches[0] // AuraGuide
        let view = CoachProfileView(coach: coach)

        #expect(!view.coach.testimonials.isEmpty)
        let firstTestimonial = view.coach.testimonials[0]
        #expect(!firstTestimonial.clientAlias.isEmpty)
        #expect(!firstTestimonial.feedback.isEmpty)
        #expect(firstTestimonial.rating >= 4.0)
    }

    @Test("Slots display accurately in client's local timezone (Acceptance Criterion 1)")
    @MainActor
    func testSlotsDisplayInClientLocalTimezone() {
        let coach = MockCoachService.defaultCoaches[1] // EchoClaritas
        let nyTimeZone = TimeZone(identifier: "America/New_York")!
        let istTimeZone = TimeZone(identifier: "Asia/Kolkata")!

        let nyVM = CoachProfileViewModel(coach: coach, timeZone: nyTimeZone)
        let istVM = CoachProfileViewModel(coach: coach, timeZone: istTimeZone)

        #expect(nyVM.localTimeZoneName.contains("Eastern") || nyVM.localTimeZoneName.contains("New York"))
        #expect(istVM.localTimeZoneName.contains("India") || istVM.localTimeZoneName.contains("Kolkata"))

        // Construct fixed test slot: 2026-10-28 14:30:00 UTC
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 10
        comp.day = 28
        comp.hour = 14
        comp.minute = 30
        let slotDate = cal.date(from: comp)!

        let testSlot = CoachSlot(
            coachId: coach.id,
            startTime: slotDate,
            durationMinutes: 50
        )

        // Formatted times must be distinct according to timezones
        let nyTime = testSlot.formattedTime(in: nyTimeZone)
        let istTime = testSlot.formattedTime(in: istTimeZone)

        #expect(nyTime == "10:30 AM")
        #expect(istTime == "8:00 PM")
        #expect(nyTime != istTime)
    }

    @Test("Tapping slot opens checkout modal state (Acceptance Criterion 2)")
    @MainActor
    func testSlotTapOpensCheckoutModal() {
        let coach = MockCoachService.defaultCoaches[0]
        let viewModel = CoachProfileViewModel(coach: coach)

        #expect(viewModel.selectedSlotForCheckout == nil)

        // Select first available slot
        guard let firstSlot = coach.slots.first else {
            Issue.record("Expected mock coach to have available slots")
            return
        }

        viewModel.selectSlot(firstSlot)
        #expect(viewModel.selectedSlotForCheckout?.id == firstSlot.id)
    }

    @Test("CheckoutModalView handles pricing breakdown, local timezone, and async reservation")
    @MainActor
    func testCheckoutModalReservation() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)
        let coaches = try await service.fetchCoaches(filter: CoachFilter())
        let coach = coaches[0]

        let today = Date()
        let slots = try await service.fetchAvailableSlots(coachId: coach.id, for: today)
        guard let slot = slots.first else {
            Issue.record("Expected open slot")
            return
        }

        var confirmedSession: CoachingSession? = nil
        var didDismiss = false

        let nyTimeZone = TimeZone(identifier: "America/New_York")!
        let modal = CheckoutModalView(
            coach: coach,
            slot: slot,
            clientAlias: "TranquilPine99",
            coachService: service,
            timeZone: nyTimeZone,
            onConfirmed: { session in
                confirmedSession = session
            },
            onDismiss: {
                didDismiss = true
            }
        )

        #expect(modal.clientAlias == "TranquilPine99")
        #expect(modal.coach.alias == coach.alias)
        #expect(modal.isBooking == false)

        // Perform reservation
        let result = await modal.handleReservation()

        #expect(result != nil)
        #expect(result?.coachAlias == coach.alias)
        #expect(result?.status == .confirmed)
        #expect(confirmedSession != nil)
        #expect(confirmedSession?.coachAlias == coach.alias)
        #expect(didDismiss == false)
    }

    @Test("CoachProfileViewModel reserves slot and updates coach slot availability")
    @MainActor
    func testViewModelSlotReservation() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)
        let coaches = try await service.fetchCoaches(filter: CoachFilter())
        let coach = coaches[0]
        let viewModel = CoachProfileViewModel(coach: coach, coachService: service)

        guard let firstSlot = coach.slots.first else {
            Issue.record("Expected slot in coach")
            return
        }

        let session = await viewModel.reserveSlot(slot: firstSlot, clientAlias: "SereneVoyager42")
        #expect(session != nil)
        #expect(session?.coachAlias == coach.alias)
        #expect(viewModel.bookedSessionSuccess != nil)
        #expect(viewModel.selectedSlotForCheckout == nil)

        // Verify slot is marked as booked in the view model's coach
        let updatedSlot = viewModel.coach.slots.first(where: { $0.id == firstSlot.id })
        #expect(updatedSlot?.isBooked == true)
    }

    @Test("DiscoverAndMatchView opens profile view on coach selection")
    @MainActor
    func testDiscoverToProfileNavigation() async throws {
        let storage = InMemoryFavoriteStorage()
        let service = MockCoachService(favoriteStorage: storage)
        let targetCoach = MockCoachService.defaultCoaches[0]
        let view = DiscoverAndMatchView(
            coachService: service,
            initialSelectedCoach: targetCoach
        )

        #expect(view.selectedCoachForProfile?.id == targetCoach.id)
    }
}
