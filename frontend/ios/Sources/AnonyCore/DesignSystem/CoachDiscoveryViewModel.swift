import Foundation
import SwiftUI
import Combine

/// Real-time View Model driving the Coach Discovery Directory, Filter Bar, and Blind Match flows.
@MainActor
public final class CoachDiscoveryViewModel: ObservableObject {
    @Published public var coaches: [Coach] = []
    @Published public var filteredCoaches: [Coach] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    // Filter States
    @Published public var selectedTopic: CoachTopic? = nil {
        didSet { applyFilters() }
    }
    @Published public var selectedICFLevel: ICFLevel? = nil {
        didSet { applyFilters() }
    }
    @Published public var selectedTier: PricingTier? = nil {
        didSet { applyFilters() }
    }
    @Published public var selectedLanguage: String? = nil {
        didSet { applyFilters() }
    }
    @Published public var showFavoritesOnly: Bool = false {
        didSet { applyFilters() }
    }

    // Favorite set cache for real-time reactivity
    @Published public private(set) var favoriteIds: Set<UUID> = []

    // Blind match state
    @Published public var isBlindMatchActive: Bool = false
    @Published public var blindMatchPrompt: String = ""
    @Published public var selectedTimeWindow: BlindMatchTimeWindow = .evening
    @Published public var selectedDate: Date = Date()
    @Published public var isBlindMatching: Bool = false
    @Published public var blindMatchResult: Coach? = nil
    @Published public var scheduledSession: ScheduledBlindMatchSession? = nil
    @Published public var blindMatchError: String? = nil
    @Published public var isCooldownActive: Bool = false
    @Published public var cooldownDaysRemaining: Int = 0
    @Published public var isLifetimeCapReached: Bool = false

    public let coachService: CoachServiceProtocol

    public init(
        coachService: CoachServiceProtocol = MockCoachService.shared,
        initialTopic: CoachTopic? = nil,
        initialTier: PricingTier? = nil
    ) {
        self.coachService = coachService
        self.selectedTopic = initialTopic
        self.selectedTier = initialTier
    }

    public func loadCoaches() async {
        isLoading = true
        do {
            let fetched = try await coachService.fetchCoaches(filter: CoachFilter())
            self.coaches = fetched
            self.favoriteIds = Set(fetched.compactMap { coachService.isFavorite(coachId: $0.id) ? $0.id : nil })
            applyFilters()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func applyFilters() {
        let filter = CoachFilter(
            topic: selectedTopic,
            icfLevel: selectedICFLevel,
            tier: selectedTier,
            language: selectedLanguage,
            favoritesOnly: showFavoritesOnly
        )
        self.filteredCoaches = coaches.filter { coach in
            let isFav = favoriteIds.contains(coach.id)
            return filter.matches(coach: coach, isFavorite: isFav)
        }
    }

    public func isFavorite(_ coachId: UUID) -> Bool {
        favoriteIds.contains(coachId)
    }

    public func toggleFavorite(for coachId: UUID) async {
        do {
            let isNowFav = try await coachService.toggleFavorite(coachId: coachId)
            if isNowFav {
                favoriteIds.insert(coachId)
            } else {
                favoriteIds.remove(coachId)
            }
            applyFilters()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    public func submitBlindMatch(profile: ClientProfile? = nil) async {
        guard !blindMatchPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isBlindMatching = true
        blindMatchError = nil
        isCooldownActive = false
        isLifetimeCapReached = false

        if let profile = profile {
            if profile.hasReachedLifetimeCap {
                self.isLifetimeCapReached = true
                self.blindMatchError = "You have completed all 6 free pro-bono sessions. Switch to Regular Mode in your profile to browse coaches and schedule paid sessions."
                self.isBlindMatching = false
                return
            }
            if profile.isCooldownActive() {
                self.isCooldownActive = true
                self.cooldownDaysRemaining = profile.daysUntilNextFreeSession()
                self.blindMatchError = "You can book 1 free pro-bono session every 14 days. Your next free session unlocks in \(profile.daysUntilNextFreeSession()) days."
                self.isBlindMatching = false
                return
            }
        }

        do {
            let matched = try await coachService.performBlindMatch(prompt: blindMatchPrompt)
            self.blindMatchResult = matched
            self.scheduledSession = ScheduledBlindMatchSession(
                coachAlias: matched.alias,
                coachIcfLevel: matched.icfLevel.badgeTitle,
                topic: blindMatchPrompt.trimmingCharacters(in: .whitespacesAndNewlines),
                scheduledTime: selectedDate,
                status: "CONFIRMED",
                isProBono: true,
                freeSessionsUsed: (profile?.freeSessionsUsed ?? 0) + 1,
                maxFreeSessions: 6,
                nextFreeSessionAvailableAt: Date().addingTimeInterval(14 * 86400)
            )
            self.isBlindMatchActive = false
        } catch {
            self.blindMatchError = error.localizedDescription
        }
        isBlindMatching = false
    }

    public func resetBlindMatch() {
        blindMatchPrompt = ""
        blindMatchResult = nil
        scheduledSession = nil
        blindMatchError = nil
        isCooldownActive = false
        cooldownDaysRemaining = 0
        isLifetimeCapReached = false
    }
}
