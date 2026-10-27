import Foundation
import SwiftUI
import Combine

/// Real-time View Model driving the Coach Profile View, Video Preview, Slot Selector, and Checkout.
@MainActor
public final class CoachProfileViewModel: ObservableObject {
    @Published public var coach: Coach
    public let coachService: CoachServiceProtocol
    public let timeZone: TimeZone

    @Published public var selectedDate: Date
    @Published public var selectedSlotForCheckout: CoachSlot? = nil
    @Published public var isPlayingVideoPreview: Bool = false
    @Published public var isFavorite: Bool
    @Published public var isBooking: Bool = false
    @Published public var bookingError: String? = nil
    @Published public var bookedSessionSuccess: CoachingSession? = nil

    public init(
        coach: Coach,
        coachService: CoachServiceProtocol = MockCoachService.shared,
        timeZone: TimeZone = .current,
        initialDate: Date = Date()
    ) {
        self.coach = coach
        self.coachService = coachService
        self.timeZone = timeZone
        self.selectedDate = initialDate
        self.isFavorite = coachService.isFavorite(coachId: coach.id)
    }

    public var localTimeZoneName: String {
        timeZone.localizedName(for: .generic, locale: Locale(identifier: "en_US")) ?? timeZone.identifier
    }

    public var localTimeZoneAbbreviation: String {
        timeZone.abbreviation(for: Date()) ?? timeZone.identifier
    }

    /// Generates next 7 consecutive calendar dates starting today in the client's timezone.
    public var calendarDays: [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
    }

    /// Available, unbooked slots matching the currently selected calendar date in the client's timezone.
    public var availableSlotsForSelectedDate: [CoachSlot] {
        coach.slots.filter { slot in
            !slot.isBooked && slot.isSameDay(as: selectedDate, in: timeZone)
        }
    }

    public func reloadCoachDetails() async {
        do {
            let refreshed = try await coachService.fetchCoachDetails(coachId: coach.id)
            self.coach = refreshed
        } catch {
            // Keep current coach on failure
        }
    }

    public func toggleFavorite() async {
        do {
            let isNowFav = try await coachService.toggleFavorite(coachId: coach.id)
            self.isFavorite = isNowFav
        } catch {
            // Ignore error
        }
    }

    public func toggleVideoPreview() {
        isPlayingVideoPreview.toggle()
    }

    public func selectSlot(_ slot: CoachSlot) {
        selectedSlotForCheckout = slot
    }

    public func reserveSlot(slot: CoachSlot, clientAlias: String) async -> CoachingSession? {
        isBooking = true
        bookingError = nil
        do {
            let session = try await coachService.bookSession(
                coachId: coach.id,
                slot: slot,
                clientAlias: clientAlias
            )
            isBooking = false
            bookedSessionSuccess = session
            selectedSlotForCheckout = nil

            // Mark slot locally as booked
            if let idx = coach.slots.firstIndex(where: { $0.id == slot.id }) {
                var updatedSlots = coach.slots
                updatedSlots[idx].isBooked = true

                self.coach = Coach(
                    id: coach.id,
                    alias: coach.alias,
                    title: coach.title,
                    specialty: coach.specialty,
                    topic: coach.topic,
                    tier: coach.tier,
                    icfLevel: coach.icfLevel,
                    languages: coach.languages,
                    hourlyRate: coach.hourlyRate,
                    rating: coach.rating,
                    sessionCount: coach.sessionCount + 1,
                    avatarSeed: coach.avatarSeed,
                    availableSlots: coach.availableSlots,
                    bio: coach.bio,
                    philosophy: coach.philosophy,
                    photoURL: coach.photoURL,
                    videoPreviewTitle: coach.videoPreviewTitle,
                    videoPreviewDuration: coach.videoPreviewDuration,
                    testimonials: coach.testimonials,
                    slots: updatedSlots
                )
            }
            return session
        } catch {
            isBooking = false
            bookingError = error.localizedDescription
            return nil
        }
    }
}
