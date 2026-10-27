import Foundation
import Testing
@testable import AnonyCore

@Suite("CoachProfileModelTests")
struct CoachProfileModelTests {

    @Test("CoachTestimonial conforms to Codable, Identifiable, Sendable")
    func testCoachTestimonialCodable() throws {
        let testimonial = CoachTestimonial(
            clientAlias: "SerenePine42",
            struggleCategory: .burnout,
            feedback: "Echo clarified my leadership boundaries within 30 minutes without feeling judged.",
            rating: 5.0,
            dateString: "2 weeks ago"
        )

        #expect(testimonial.clientAlias == "SerenePine42")
        #expect(testimonial.struggleCategory == .burnout)
        #expect(testimonial.rating == 5.0)

        let encoder = JSONEncoder()
        let data = try encoder.encode(testimonial)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CoachTestimonial.self, from: data)

        #expect(decoded == testimonial)
    }

    @Test("CoachSlot formats time and date in specified client timezones accurately")
    func testCoachSlotTimezoneConversion() throws {
        // Construct fixed UTC date: 2026-10-28 14:30:00 UTC
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 28
        components.hour = 14
        components.minute = 30
        components.second = 0
        let utcDate = calendar.date(from: components)!

        let coachId = UUID()
        let slot = CoachSlot(
            coachId: coachId,
            startTime: utcDate,
            durationMinutes: 50,
            isBooked: false
        )

        // In New York (EDT, UTC-4), 14:30 UTC is 10:30 AM
        let nyTimeZone = TimeZone(identifier: "America/New_York")!
        #expect(slot.formattedTime(in: nyTimeZone) == "10:30 AM")
        #expect(slot.formattedDate(in: nyTimeZone) == "Wed, Oct 28")

        // In Kolkata (IST, UTC+5:30), 14:30 UTC is 8:00 PM
        let istTimeZone = TimeZone(identifier: "Asia/Kolkata")!
        #expect(slot.formattedTime(in: istTimeZone) == "8:00 PM")
        #expect(slot.formattedDate(in: istTimeZone) == "Wed, Oct 28")

        // In Tokyo (JST, UTC+9), 14:30 UTC is 11:30 PM
        let tokyoTimeZone = TimeZone(identifier: "Asia/Tokyo")!
        #expect(slot.formattedTime(in: tokyoTimeZone) == "11:30 PM")

        // Slot same day comparison check
        #expect(slot.isSameDay(as: utcDate, in: nyTimeZone))
    }

    @Test("Coach model backward-compatible decoding with default fields")
    func testCoachBackwardCompatibilityDecoding() throws {
        // Minimal JSON representation mimicking older payloads missing bio, philosophy, testimonials, etc.
        let minimalJSON = """
        {
            "id": "A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D",
            "alias": "LegacyCoach",
            "title": "Senior Mentor",
            "specialty": "career",
            "tier": "paid",
            "rating": 4.95,
            "sessionCount": 150,
            "avatarSeed": "LegacyCoach"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let coach = try decoder.decode(Coach.self, from: minimalJSON)

        #expect(coach.alias == "LegacyCoach")
        #expect(!coach.bio.isEmpty)
        #expect(!coach.philosophy.isEmpty)
        #expect(coach.videoPreviewDuration == "1:00")
        #expect(coach.testimonials.isEmpty)
        #expect(coach.slots.isEmpty)
    }

    @Test("Coach model full encode and decode roundtrip")
    func testCoachFullCodableRoundtrip() throws {
        let slot = CoachSlot(
            coachId: UUID(),
            startTime: Date(),
            durationMinutes: 50
        )
        let testimonial = CoachTestimonial(
            clientAlias: "QuietRiver19",
            struggleCategory: .life,
            feedback: "Transformative session.",
            dateString: "Yesterday"
        )
        let coach = Coach(
            alias: "ComprehensiveGuide",
            title: "Holistic Mentor",
            specialty: .life,
            tier: .free,
            icfLevel: .mcc,
            languages: ["English", "French"],
            hourlyRate: 0,
            rating: 5.0,
            sessionCount: 200,
            avatarSeed: "ComprehensiveGuide",
            bio: "Experienced MCC guide.",
            philosophy: "Deep listening and presence.",
            photoURL: "https://anony.app/photo.jpg",
            videoPreviewTitle: "Watch 1-Min Coaching Demo",
            videoPreviewDuration: "1:00",
            testimonials: [testimonial],
            slots: [slot]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(coach)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Coach.self, from: data)

        #expect(decoded.alias == coach.alias)
        #expect(decoded.bio == coach.bio)
        #expect(decoded.philosophy == coach.philosophy)
        #expect(decoded.testimonials.count == 1)
        #expect(decoded.slots.count == 1)
    }
}
