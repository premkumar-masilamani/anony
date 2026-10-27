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
    private var favorites: Set<UUID>
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

// MARK: - Coach Service Protocol

public protocol CoachServiceProtocol: Sendable {
    func fetchCoaches(filter: CoachFilter) async throws -> [Coach]
    func toggleFavorite(coachId: UUID) async throws -> Bool
    func isFavorite(coachId: UUID) -> Bool
    func performBlindMatch(prompt: String) async throws -> Coach
}

// MARK: - Mock Coach Service

/// Mock coach service simulating backend REST endpoints referenced via APIEndpoints constants.
public final class MockCoachService: CoachServiceProtocol, Sendable {
    public static let shared = MockCoachService()

    private let favoriteStorage: FavoriteStorageProtocol
    private let simulateNetworkDelay: Bool

    // Default static mock directory representing diverse human coaches across all filters
    public static let defaultCoaches: [Coach] = [
        Coach(
            id: UUID(uuidString: "a0000000-0000-0000-0000-000000000001")!,
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
            availableSlots: ["Today 4:30 PM", "Tomorrow 2:30 PM", "Fri 11:00 AM"]
        ),
        Coach(
            id: UUID(uuidString: "a0000000-0000-0000-0000-000000000002")!,
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
            availableSlots: ["Today 2:30 PM", "Tomorrow 10:00 AM", "Thu 4:00 PM"]
        ),
        Coach(
            id: UUID(uuidString: "a0000000-0000-0000-0000-000000000003")!,
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
            availableSlots: ["Today 2:30 PM", "Tomorrow 3:00 PM", "Fri 10:00 AM"]
        ),
        Coach(
            id: UUID(uuidString: "a0000000-0000-0000-0000-000000000004")!,
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
            availableSlots: ["Tomorrow 2:30 PM", "Fri 2:00 PM"]
        ),
        Coach(
            id: UUID(uuidString: "a0000000-0000-0000-0000-000000000005")!,
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
            availableSlots: ["Today 5:00 PM", "Wed 1:00 PM"]
        ),
        Coach(
            id: UUID(uuidString: "a0000000-0000-0000-0000-000000000006")!,
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
            availableSlots: ["Tomorrow 11:30 AM", "Thu 6:00 PM"]
        ),
        Coach(
            id: UUID(uuidString: "a0000000-0000-0000-0000-000000000007")!,
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
            availableSlots: ["Today 3:00 PM", "Tomorrow 4:30 PM"]
        )
    ]

    private let coaches: [Coach]

    public init(
        coaches: [Coach] = MockCoachService.defaultCoaches,
        favoriteStorage: FavoriteStorageProtocol = UserDefaultsFavoriteStorage.shared,
        simulateNetworkDelay: Bool = false
    ) {
        self.coaches = coaches
        self.favoriteStorage = favoriteStorage
        self.simulateNetworkDelay = simulateNetworkDelay
    }

    /// Simulates GET request to APIEndpoints.coaches with query parameters.
    public func fetchCoaches(filter: CoachFilter) async throws -> [Coach] {
        // Reference endpoint path in accordance with project architecture
        _ = APIEndpoints.coaches

        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms realistic delay
        }

        let favorites = favoriteStorage.getFavorites()

        return coaches.filter { coach in
            let isFav = favorites.contains(coach.id)
            return filter.matches(coach: coach, isFavorite: isFav)
        }
    }

    /// Simulates POST request to APIEndpoints.coachFavorite(id:) to toggle favorite status.
    public func toggleFavorite(coachId: UUID) async throws -> Bool {
        // Reference endpoint path in accordance with project architecture
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

    /// Simulates POST request to APIEndpoints.blindMatch with semantic struggle prompt.
    public func performBlindMatch(prompt: String) async throws -> Coach {
        // Reference endpoint path in accordance with project architecture
        _ = APIEndpoints.blindMatch

        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: 60_000_000) // 60ms realistic delay
        }

        let lower = prompt.lowercased()

        // Prioritize free tier coaches for blind match mode
        let freeCoaches = coaches.filter { $0.tier == .free }

        // Semantic scoring based on struggle prompt keywords
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

        // Default to first available pro-bono coach
        return freeCoaches.first ?? coaches[0]
    }
}
