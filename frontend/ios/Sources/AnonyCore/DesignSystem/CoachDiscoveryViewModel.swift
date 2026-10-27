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
    @Published public var isBlindMatching: Bool = false
    @Published public var blindMatchResult: Coach? = nil
    @Published public var blindMatchError: String? = nil

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

    public func submitBlindMatch() async {
        guard !blindMatchPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isBlindMatching = true
        blindMatchError = nil
        do {
            let matched = try await coachService.performBlindMatch(prompt: blindMatchPrompt)
            self.blindMatchResult = matched
            self.isBlindMatchActive = false
        } catch {
            self.blindMatchError = error.localizedDescription
        }
        isBlindMatching = false
    }

    public func resetBlindMatch() {
        blindMatchPrompt = ""
        blindMatchResult = nil
        blindMatchError = nil
    }
}
