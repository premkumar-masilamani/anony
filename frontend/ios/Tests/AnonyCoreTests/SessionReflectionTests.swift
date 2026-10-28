import Foundation
import Testing
@testable import AnonyCore

@Suite("SessionReflection & Testimonial Tests", .serialized)
struct SessionReflectionTests {

    @Test("SessionReflection enforces 1 to 5 rating range")
    func testRatingValidation() {
        let sessionId = UUID()
        
        // Valid ratings 1 to 5
        let reflection1 = SessionReflection(
            sessionId: sessionId,
            coachAlias: "Coach Elena",
            rating: 1,
            publicTestimonial: "Truly calming.",
            privateReflectionNote: "Felt understood.",
            quickTags: ["Calm"]
        )
        #expect(reflection1.rating == 1)
        #expect(reflection1.isValidRating)

        let reflection5 = SessionReflection(
            sessionId: sessionId,
            coachAlias: "Coach Elena",
            rating: 5,
            publicTestimonial: "Phenomenal guidance.",
            privateReflectionNote: "Great breathing cues.",
            quickTags: ["Clarity", "Grounded"]
        )
        #expect(reflection5.rating == 5)
        #expect(reflection5.isValidRating)

        // Rating outside 1...5
        let invalidLow = SessionReflection(
            sessionId: sessionId,
            coachAlias: "Coach Elena",
            rating: 0
        )
        #expect(!invalidLow.isValidRating)

        let invalidHigh = SessionReflection(
            sessionId: sessionId,
            coachAlias: "Coach Elena",
            rating: 6
        )
        #expect(!invalidHigh.isValidRating)
    }

    @Test("SessionReflection converts to CoachTestimonial omitting private reflection note")
    func testConversionToCoachTestimonialZeroPII() {
        let sessionId = UUID()
        let reflection = SessionReflection(
            sessionId: sessionId,
            coachAlias: "Coach Elena",
            rating: 5,
            publicTestimonial: "The mindfulness exercise helped me ground myself.",
            privateReflectionNote: "Personal note: Remind myself to practice box breathing at 3pm.",
            quickTags: ["Grounded", "Clarity"]
        )

        let testimonial = reflection.toCoachTestimonial(
            clientAlias: "Quiet Meadow",
            category: .burnout,
            dateString: "Oct 2026"
        )

        #expect(testimonial != nil)
        #expect(testimonial?.clientAlias == "Quiet Meadow")
        #expect(testimonial?.feedback == "The mindfulness exercise helped me ground myself.")
        #expect(testimonial?.rating == 5.0)
        #expect(testimonial?.struggleCategory == .burnout)

        // Verify private reflection note is strictly NOT present in public testimonial
        #expect(testimonial?.feedback.contains("box breathing") == false)
    }

    @Test("SessionReflection toCoachTestimonial returns nil if public testimonial is blank")
    func testConversionWithEmptyPublicTestimonialReturnsNil() {
        let reflection = SessionReflection(
            sessionId: UUID(),
            coachAlias: "Coach Elena",
            rating: 4,
            publicTestimonial: "   ",
            privateReflectionNote: "Personal reflection only.",
            quickTags: ["Calm"]
        )

        let testimonial = reflection.toCoachTestimonial(
            clientAlias: "Tranquil River",
            category: .career,
            dateString: "Oct 2026"
        )

        #expect(testimonial == nil)
    }

    @Test("SessionReflectionService persists and retrieves reflections securely")
    func testSessionReflectionServicePersistence() async throws {
        let testIdentifier = "test.reflection.\(UUID().uuidString)"
        let service = SessionReflectionService(storageIdentifier: testIdentifier)

        let sessionId = UUID()
        let reflection = SessionReflection(
            sessionId: sessionId,
            coachAlias: "Coach Marcus",
            rating: 5,
            publicTestimonial: "Helped me unpack heavy emotions without judgment.",
            privateReflectionNote: "Private key takeaway: Accept uncertainty.",
            quickTags: ["Heard", "Actionable Steps"]
        )

        try await service.saveReflection(reflection)

        let retrieved = await service.getReflection(for: sessionId)
        #expect(retrieved != nil)
        #expect(retrieved?.sessionId == sessionId)
        #expect(retrieved?.coachAlias == "Coach Marcus")
        #expect(retrieved?.rating == 5)
        #expect(retrieved?.publicTestimonial == "Helped me unpack heavy emotions without judgment.")
        #expect(retrieved?.privateReflectionNote == "Private key takeaway: Accept uncertainty.")
        #expect(retrieved?.quickTags == ["Heard", "Actionable Steps"])

        let all = await service.allReflections()
        #expect(all.count == 1)
        #expect(all.first?.sessionId == sessionId)

        // Clean up test storage
        await service.clearStorage()
    }

    @Test("CoachingSession reflection properties and alert status")
    func testCoachingSessionWithReflection() {
        let sessionId = UUID()
        let baseDate = Date(timeIntervalSince1970: 1700000000)

        // Session completed without reflection triggers postSessionReflection alert
        let completedSessionWithoutReflection = CoachingSession(
            id: sessionId,
            coachAlias: "Coach Elena",
            coachAvatarSeed: "ElenaSeed",
            category: .burnout,
            tier: .paid,
            scheduledDate: baseDate,
            timeSlot: "10:00 AM",
            timeZoneIdentifier: "UTC",
            status: .completed,
            hasReflection: false
        )

        #expect(!completedSessionWithoutReflection.hasReflection)
        let alert = completedSessionWithoutReflection.reminderAlert(at: baseDate.addingTimeInterval(3600))
        #expect(alert == .postSessionReflection(coachName: "Coach Elena"))
        #expect(alert?.systemImage == "star.bubble.fill")

        // Session completed WITH reflection returns nil alert
        let completedWithReflection = CoachingSession(
            id: sessionId,
            coachAlias: "Coach Elena",
            coachAvatarSeed: "ElenaSeed",
            category: .burnout,
            tier: .paid,
            scheduledDate: baseDate,
            timeSlot: "10:00 AM",
            timeZoneIdentifier: "UTC",
            status: .completed,
            hasReflection: true
        )

        #expect(completedWithReflection.hasReflection)
        let alertAfter = completedWithReflection.reminderAlert(at: baseDate.addingTimeInterval(3600))
        #expect(alertAfter == nil)
    }
}
