import Foundation

// MARK: - Favorite Storage Protocol & Implementations

/// Protocol defining local persistence for client coach favorites.
public protocol FavoriteStorageProtocol: AnyObject, Sendable {
    func getFavorites() -> Set<UUID>
    func saveFavorites(_ favorites: Set<UUID>)
}

/// Persistent coach favorite storage backed by iOS UserDefaults.
public final class UserDefaultsFavoriteStorage: FavoriteStorageProtocol, @unchecked Sendable {
    public static let shared = UserDefaultsFavoriteStorage()

    private let userDefaults: UserDefaults
    private let storageKey = "anony.coach.favorites"
    private let lock = NSLock()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func getFavorites() -> Set<UUID> {
        lock.lock()
        defer { lock.unlock() }

        guard let strings = userDefaults.stringArray(forKey: storageKey) else {
            return []
        }
        let uuids = strings.compactMap { UUID(uuidString: $0) }
        return Set(uuids)
    }

    public func saveFavorites(_ favorites: Set<UUID>) {
        lock.lock()
        defer { lock.unlock() }

        let strings = favorites.map(\.uuidString)
        userDefaults.set(strings, forKey: storageKey)
    }
}

/// In-memory favorite storage for unit testing and SwiftUI previews.
public final class InMemoryFavoriteStorage: FavoriteStorageProtocol, @unchecked Sendable {
    private var favorites: Set<UUID> = []
    private let lock = NSLock()

    public init(initialFavorites: Set<UUID> = []) {
        self.favorites = initialFavorites
    }

    public func getFavorites() -> Set<UUID> {
        lock.lock()
        defer { lock.unlock() }
        return favorites
    }

    public func saveFavorites(_ favorites: Set<UUID>) {
        lock.lock()
        defer { lock.unlock() }
        self.favorites = favorites
    }
}

// MARK: - Coach Service Errors

public enum CoachServiceError: Error, LocalizedError, Sendable, Equatable {
    case coachNotFound
    case slotUnavailable
    case bookingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .coachNotFound:
            return "Coach profile not found."
        case .slotUnavailable:
            return "The selected slot is no longer available."
        case .bookingFailed(let reason):
            return "Booking failed: \(reason)"
        }
    }
}

// MARK: - Coach Service Protocol

public protocol CoachServiceProtocol: Sendable {
    func fetchCoaches(filter: CoachFilter) async throws -> [Coach]
    func fetchCoachDetails(coachId: UUID) async throws -> Coach
    func fetchAvailableSlots(coachId: UUID, for date: Date) async throws -> [CoachSlot]
    func bookSession(coachId: UUID, slot: CoachSlot, clientAlias: String) async throws -> CoachingSession
    func toggleFavorite(coachId: UUID) async throws -> Bool
    func isFavorite(coachId: UUID) -> Bool
    func performBlindMatch(prompt: String) async throws -> Coach
}

// MARK: - Mock Coach Service

/// Mock coach service simulating backend REST endpoints referenced via APIEndpoints constants.
public final class MockCoachService: CoachServiceProtocol, @unchecked Sendable {
    public static let shared = MockCoachService()

    private let favoriteStorage: FavoriteStorageProtocol
    private let simulateNetworkDelay: Bool
    private var coaches: [Coach]
    private let stateLock = NSLock()

    private static func generateDefaultSlots(coachId: UUID) -> [CoachSlot] {
        var slots: [CoachSlot] = []
        let calendar = Calendar.current
        let baseDate = Date()
        let hoursAndMinutes = [(10, 0), (14, 30), (16, 30), (19, 0)]
        for dayOffset in 0..<30 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: baseDate) else { continue }
            for (h, m) in hoursAndMinutes {
                var comp = calendar.dateComponents([.year, .month, .day], from: dayDate)
                comp.hour = h
                comp.minute = m
                comp.second = 0
                if let slotDate = calendar.date(from: comp) {
                    slots.append(CoachSlot(
                        coachId: coachId,
                        startTime: slotDate,
                        durationMinutes: 50,
                        isBooked: false
                    ))
                }
            }
        }
        return slots
    }

    // Default static mock directory representing diverse human coaches across all filters
    public static let defaultCoaches: [Coach] = {
        let auraId = UUID(uuidString: "a0000000-0000-0000-0000-000000000001")!
        let echoId = UUID(uuidString: "a0000000-0000-0000-0000-000000000002")!
        let zephyrId = UUID(uuidString: "a0000000-0000-0000-0000-000000000003")!
        let solaceId = UUID(uuidString: "a0000000-0000-0000-0000-000000000004")!
        let harmoniaId = UUID(uuidString: "a0000000-0000-0000-0000-000000000005")!
        let sereneId = UUID(uuidString: "a0000000-0000-0000-0000-000000000006")!
        let vanguardId = UUID(uuidString: "a0000000-0000-0000-0000-000000000007")!

        return [
            Coach(
                id: auraId,
                alias: "AuraGuide",
                title: "Resilience & Burnout Recovery",
                specialty: .burnout,
                topic: .careerBurnout,
                tier: .free,
                icfLevel: .pcc,
                languages: ["English", "Spanish"],
                hourlyRate: 0,
                rating: 4.96,
                sessionCount: 184,
                avatarSeed: "AuraGuide",
                availableSlots: ["Today 4:30 PM", "Tomorrow 2:30 PM", "Fri 11:00 AM"],
                bio: "ICF Professional Certified Coach (PCC) specializing in nervous system restoration, sustainable pacing, and emotional renewal for high-stress contributors.",
                philosophy: "Burnout is not personal inadequacy; it is an unsustainable environmental demand. In audio-only dialogue, we strip away performance pressure so your genuine energy emerges.",
                videoPreviewTitle: "1-Min Voice Preview: The Reset Mindset",
                videoPreviewDuration: "1:00",
                testimonials: [
                    CoachTestimonial(
                        clientAlias: "TranquilPine31",
                        struggleCategory: .burnout,
                        feedback: "Aura created a non-judgmental container where I could finally breathe. My workday anxiety dropped substantially after two sessions.",
                        rating: 5.0,
                        dateString: "1 week ago"
                    ),
                    CoachTestimonial(
                        clientAlias: "QuietBreeze88",
                        struggleCategory: .burnout,
                        feedback: "Zero video made me feel so much safer opening up about feeling overwhelmed. Truly life-restoring guidance.",
                        rating: 4.9,
                        dateString: "3 weeks ago"
                    )
                ],
                slots: generateDefaultSlots(coachId: auraId)
            ),
            Coach(
                id: echoId,
                alias: "EchoClaritas",
                title: "Executive & Career Navigation",
                specialty: .career,
                topic: .executive,
                tier: .paid,
                icfLevel: .mcc,
                languages: ["English", "French"],
                hourlyRate: 150,
                rating: 4.98,
                sessionCount: 312,
                avatarSeed: "EchoClaritas",
                availableSlots: ["Today 2:30 PM", "Tomorrow 10:00 AM", "Thu 4:00 PM"],
                bio: "ICF Master Certified Coach (MCC) with 15+ years advising founders, engineering executives, and senior leaders navigating organizational crossroads and strategic clarity.",
                philosophy: "Decisions made from anxiety breed paralysis. We cultivate ontological clarity: aligning what you value with how you lead and negotiate.",
                videoPreviewTitle: "1-Min Voice Preview: Navigating Executive Crossroads",
                videoPreviewDuration: "1:00",
                testimonials: [
                    CoachTestimonial(
                        clientAlias: "SereneMeadow12",
                        struggleCategory: .career,
                        feedback: "Echo cut straight through my career indecision in 45 minutes. The most efficient and clarifying session I have ever had.",
                        rating: 5.0,
                        dateString: "4 days ago"
                    ),
                    CoachTestimonial(
                        clientAlias: "SilentRiver04",
                        struggleCategory: .career,
                        feedback: "Exceptional executive perspective. Kept my anonymity 100% sacred while giving transformative feedback.",
                        rating: 5.0,
                        dateString: "2 weeks ago"
                    )
                ],
                slots: generateDefaultSlots(coachId: echoId)
            ),
            Coach(
                id: zephyrId,
                alias: "ZephyrMind",
                title: "Life Alignment & Transitions",
                specialty: .life,
                topic: .life,
                tier: .free,
                icfLevel: .acc,
                languages: ["English", "German"],
                hourlyRate: 0,
                rating: 4.91,
                sessionCount: 97,
                avatarSeed: "ZephyrMind",
                availableSlots: ["Today 2:30 PM", "Tomorrow 3:00 PM", "Fri 10:00 AM"],
                bio: "ICF Associate Certified Coach (ACC) focusing on life purpose, habit redesign, and navigating unfamiliar personal milestones without friction.",
                philosophy: "Transitions feel disorienting because we cling to obsolete narratives. We hold gentle inquiries to map out your next authentic chapter.",
                videoPreviewTitle: "1-Min Voice Preview: Grounding Life Transitions",
                videoPreviewDuration: "1:00",
                testimonials: [
                    CoachTestimonial(
                        clientAlias: "GentleWillow55",
                        struggleCategory: .life,
                        feedback: "Zephyr helped me make peace with an overwhelming life pivot. Warm, grounded, and deeply attentive.",
                        rating: 4.9,
                        dateString: "5 days ago"
                    )
                ],
                slots: generateDefaultSlots(coachId: zephyrId)
            ),
            Coach(
                id: solaceId,
                alias: "SolaceVessel",
                title: "Deep Stress & Boundary Restoration",
                specialty: .burnout,
                topic: .careerBurnout,
                tier: .paid,
                icfLevel: .mcc,
                languages: ["English"],
                hourlyRate: 180,
                rating: 4.99,
                sessionCount: 420,
                avatarSeed: "SolaceVessel",
                availableSlots: ["Tomorrow 2:30 PM", "Fri 2:00 PM"],
                bio: "Master Certified Coach with 2,500+ verified coaching hours. Specializing in somatic boundary work, toxic workplace recovery, and nervous system calm.",
                philosophy: "Boundaries are not walls; they are conditions that allow you to give your best self without self-abandonment.",
                videoPreviewTitle: "1-Min Voice Preview: Setting Sacred Boundaries",
                videoPreviewDuration: "1:00",
                testimonials: [
                    CoachTestimonial(
                        clientAlias: "CalmCreek73",
                        struggleCategory: .burnout,
                        feedback: "Solace taught me how to say no without guilt. A masterclass in presence and calm guidance.",
                        rating: 5.0,
                        dateString: "1 month ago"
                    )
                ],
                slots: generateDefaultSlots(coachId: solaceId)
            ),
            Coach(
                id: harmoniaId,
                alias: "HarmoniaBridge",
                title: "Interpersonal & Couple Communication",
                specialty: .life,
                topic: .relationship,
                tier: .paid,
                icfLevel: .pcc,
                languages: ["English", "Spanish"],
                hourlyRate: 135,
                rating: 4.94,
                sessionCount: 215,
                avatarSeed: "HarmoniaBridge",
                availableSlots: ["Today 5:00 PM", "Wed 1:00 PM"],
                bio: "ICF PCC coach helping individuals de-escalate interpersonal conflicts, develop active listening skills, and create healthy emotional agreements.",
                philosophy: "When we listen to defend, we lose connection. We practice mindful conversational inquiry to build empathy and mutual trust.",
                videoPreviewTitle: "1-Min Voice Preview: De-escalating Friction",
                videoPreviewDuration: "1:00",
                testimonials: [
                    CoachTestimonial(
                        clientAlias: "SereneStone90",
                        struggleCategory: .life,
                        feedback: "Harmonia helped me articulate what I needed without triggering defensiveness. Transformational insight.",
                        rating: 4.9,
                        dateString: "2 weeks ago"
                    )
                ],
                slots: generateDefaultSlots(coachId: harmoniaId)
            ),
            Coach(
                id: sereneId,
                alias: "SereneCompass",
                title: "Community Pro-Bono Life Crossroads",
                specialty: .life,
                topic: .relationship,
                tier: .free,
                icfLevel: .acc,
                languages: ["English", "Mandarin"],
                hourlyRate: 0,
                rating: 4.89,
                sessionCount: 78,
                avatarSeed: "SereneCompass",
                availableSlots: ["Tomorrow 11:30 AM", "Thu 6:00 PM"],
                bio: "Community pro-bono coach dedicated to providing accessible, zero-cost life guidance to underserved voices and individuals facing sudden crossroads.",
                philosophy: "High-quality human coaching must not be a luxury reserved for the few. Everyone deserves a confidential sounding board.",
                videoPreviewTitle: "1-Min Voice Preview: A Compass in the Fog",
                videoPreviewDuration: "1:00",
                testimonials: [
                    CoachTestimonial(
                        clientAlias: "QuietMeadow42",
                        struggleCategory: .life,
                        feedback: "Getting this quality of coaching pro-bono changed everything for me. Invaluable platform.",
                        rating: 4.9,
                        dateString: "3 days ago"
                    )
                ],
                slots: generateDefaultSlots(coachId: sereneId)
            ),
            Coach(
                id: vanguardId,
                alias: "VanguardLead",
                title: "High-Growth Leadership & Team Trust",
                specialty: .career,
                topic: .executive,
                tier: .free,
                icfLevel: .pcc,
                languages: ["English"],
                hourlyRate: 0,
                rating: 4.93,
                sessionCount: 160,
                avatarSeed: "VanguardLead",
                availableSlots: ["Today 3:00 PM", "Tomorrow 4:30 PM"],
                bio: "Former tech executive turned PCC coach offering pro-bono sessions to new engineering managers and early team leads building psychological safety.",
                philosophy: "Great leadership is not having all the answers; it is framing the right inquiries and holding space for collective wisdom.",
                videoPreviewTitle: "1-Min Voice Preview: Leadership Through Inquiry",
                videoPreviewDuration: "1:00",
                testimonials: [
                    CoachTestimonial(
                        clientAlias: "PeacefulBreeze14",
                        struggleCategory: .career,
                        feedback: "Vanguard gave me tactical frameworks that transformed how I run my 1-on-1s. Highly recommend.",
                        rating: 5.0,
                        dateString: "1 week ago"
                    )
                ],
                slots: generateDefaultSlots(coachId: vanguardId)
            )
        ]
    }()

    public init(
        coaches: [Coach] = MockCoachService.defaultCoaches,
        favoriteStorage: FavoriteStorageProtocol = UserDefaultsFavoriteStorage.shared,
        simulateNetworkDelay: Bool = false
    ) {
        self.coaches = coaches
        self.favoriteStorage = favoriteStorage
        self.simulateNetworkDelay = simulateNetworkDelay
    }

    // MARK: - Synchronous State Accessors (Avoids NSLock in async context)

    private func getCoachesSnapshot() -> [Coach] {
        stateLock.lock()
        defer { stateLock.unlock() }
        return coaches
    }

    private func findCoach(by id: UUID) -> Coach? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return coaches.first(where: { $0.id == id })
    }

    private func reserveSlot(coachId: UUID, slotId: UUID) throws -> (Coach, CoachSlot) {
        stateLock.lock()
        defer { stateLock.unlock() }

        guard let coachIndex = coaches.firstIndex(where: { $0.id == coachId }) else {
            throw CoachServiceError.coachNotFound
        }

        let coach = coaches[coachIndex]

        guard let slotIndex = coach.slots.firstIndex(where: { $0.id == slotId }) else {
            throw CoachServiceError.slotUnavailable
        }

        if coach.slots[slotIndex].isBooked {
            throw CoachServiceError.slotUnavailable
        }

        var updatedSlots = coach.slots
        updatedSlots[slotIndex].isBooked = true

        let updatedCoach = Coach(
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
        coaches[coachIndex] = updatedCoach
        return (updatedCoach, updatedSlots[slotIndex])
    }

    // MARK: - Protocol Methods

    /// Simulates GET request to APIEndpoints.coaches with query parameters.
    public func fetchCoaches(filter: CoachFilter) async throws -> [Coach] {
        _ = APIEndpoints.coaches

        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms realistic delay
        }

        let favorites = favoriteStorage.getFavorites()
        let currentCoaches = getCoachesSnapshot()

        return currentCoaches.filter { coach in
            let isFav = favorites.contains(coach.id)
            return filter.matches(coach: coach, isFavorite: isFav)
        }
    }

    /// Simulates GET request to APIEndpoints.coachDetails(id:).
    public func fetchCoachDetails(coachId: UUID) async throws -> Coach {
        _ = APIEndpoints.coachDetails(id: coachId)

        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: 40_000_000)
        }

        guard let coach = findCoach(by: coachId) else {
            throw CoachServiceError.coachNotFound
        }
        return coach
    }

    /// Simulates GET request to APIEndpoints.coachSlots(id:) filtering for client's target date.
    public func fetchAvailableSlots(coachId: UUID, for date: Date) async throws -> [CoachSlot] {
        _ = APIEndpoints.coachSlots(id: coachId)

        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: 40_000_000)
        }

        guard let coach = findCoach(by: coachId) else {
            throw CoachServiceError.coachNotFound
        }

        return coach.slots.filter { slot in
            !slot.isBooked && slot.isSameDay(as: date, in: .current)
        }
    }

    /// Simulates POST request to APIEndpoints.sessions.
    public func bookSession(coachId: UUID, slot: CoachSlot, clientAlias: String) async throws -> CoachingSession {
        _ = APIEndpoints.sessions

        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: 60_000_000)
        }

        let (coach, bookedSlot) = try reserveSlot(coachId: coachId, slotId: slot.id)

        let session = CoachingSession(
            id: UUID(),
            coachAlias: coach.alias,
            coachAvatarSeed: coach.avatarSeed,
            category: coach.specialty,
            tier: coach.tier,
            scheduledDate: bookedSlot.startTime,
            timeSlot: bookedSlot.formattedTime(in: .current),
            timeZoneIdentifier: TimeZone.current.identifier,
            status: .confirmed
        )

        return session
    }

    /// Simulates POST request to APIEndpoints.coachFavorite(id:) to toggle favorite status.
    public func toggleFavorite(coachId: UUID) async throws -> Bool {
        _ = APIEndpoints.coachFavorite(id: coachId)

        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: 30_000_000) // 30ms realistic delay
        }

        var favorites = favoriteStorage.getFavorites()
        let isNowFavorite: Bool
        if favorites.contains(coachId) {
            favorites.remove(coachId)
            isNowFavorite = false
        } else {
            favorites.insert(coachId)
            isNowFavorite = true
        }
        favoriteStorage.saveFavorites(favorites)
        return isNowFavorite
    }

    public func isFavorite(coachId: UUID) -> Bool {
        favoriteStorage.getFavorites().contains(coachId)
    }

    /// Simulates POST request to APIEndpoints.sessions with semantic struggle prompt.
    public func performBlindMatch(prompt: String) async throws -> Coach {
        _ = APIEndpoints.sessions

        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: 60_000_000) // 60ms realistic delay
        }

        let lower = prompt.lowercased()
        let currentCoaches = getCoachesSnapshot()

        let freeCoaches = currentCoaches.filter { $0.tier == .free }

        if lower.contains("executive") || lower.contains("leadership") || lower.contains("strategy") {
            if let coach = freeCoaches.first(where: { $0.topic == .executive }) {
                return coach
            }
        }

        if lower.contains("burnout") || lower.contains("exhaust") || lower.contains("stress") || lower.contains("overwhelm") {
            if let coach = freeCoaches.first(where: { $0.topic == .careerBurnout }) {
                return coach
            }
        }

        if lower.contains("relation") || lower.contains("partner") || lower.contains("conflict") || lower.contains("communication") {
            if let coach = freeCoaches.first(where: { $0.topic == .relationship }) {
                return coach
            }
        }

        if lower.contains("life") || lower.contains("purpose") || lower.contains("meaning") || lower.contains("direction") {
            if let coach = freeCoaches.first(where: { $0.topic == .life }) {
                return coach
            }
        }

        return freeCoaches.first ?? currentCoaches[0]
    }
}
