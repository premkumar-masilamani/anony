import SwiftUI

/// 3-Tab Main Shell for authenticated clients:
/// - Discover & Match: Curated verified human coaches filtered by preferences and availability
/// - Muse Voice Guide: Educational audio guide explaining what coaching is and how to prepare
/// - My Sessions: Scheduled 1-on-1 anonymous audio calls with human coaches
public struct MainShellView: View {
    public let userAlias: String?
    public let userEmail: String?
    public let onboardingService: OnboardingServiceProtocol
    public let profileService: ProfileServiceProtocol
    public let onSignOut: () -> Void

    @State private var selectedTab: Int = 0
    @State private var showingProfile: Bool = false
    @State private var currentAlias: String
    @State private var currentEmail: String
    @State private var isAnonymousMode: Bool

    public init(
        userAlias: String? = nil,
        userEmail: String? = nil,
        onboardingService: OnboardingServiceProtocol = UserDefaultsOnboardingService.shared,
        profileService: ProfileServiceProtocol = UserDefaultsProfileService.shared,
        onSignOut: @escaping () -> Void
    ) {
        self.userAlias = userAlias
        self.userEmail = userEmail
        self.onboardingService = onboardingService
        self.profileService = profileService
        self.onSignOut = onSignOut

        let profile = profileService.getProfile()
        self._currentAlias = State(initialValue: userAlias ?? profile.alias)
        self._currentEmail = State(initialValue: userEmail ?? profile.email)
        self._isAnonymousMode = State(initialValue: profile.isAnonymousMode)
    }

    public var body: some View {
        ZStack {
            ColorPalette.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Client Header
                clientHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // 3-Tab Content
                TabView(selection: $selectedTab) {
                    let preferences = onboardingService.getPreferences()

                    DiscoverAndMatchView(
                        initialCategory: preferences?.struggleCategory,
                        initialTier: preferences?.pricingTier,
                        profileService: profileService,
                        isAnonymousMode: isAnonymousMode
                    )
                    .tabItem {
                        Label(
                            isAnonymousMode ? "Blind Match" : "Discover & Match",
                            systemImage: isAnonymousMode ? "sparkles" : "sparkle.magnifyingglass"
                        )
                    }
                    .tag(0)

                    MuseVoiceGuideCompanionView()
                        .tabItem {
                            Label("Muse Voice Guide", systemImage: "waveform.circle.fill")
                        }
                        .tag(1)

                    MySessionsView(preferences: preferences)
                        .tabItem {
                            Label("My Sessions", systemImage: "calendar.badge.clock")
                        }
                        .tag(2)
                }
                .tint(ColorPalette.calmingCyan)
            }
        }
        .sheet(isPresented: $showingProfile) {
            MyProfileView(
                profileService: profileService,
                onProfileUpdated: { updated in
                    currentAlias = updated.alias
                    currentEmail = updated.email
                    isAnonymousMode = updated.isAnonymousMode
                },
                onDismiss: {
                    showingProfile = false
                }
            )
        }
    }

    private var clientHeader: some View {
        HStack(spacing: 12) {
            Button {
                showingProfile = true
            } label: {
                HStack(spacing: 12) {
                    AvatarCircleView(seed: currentAlias, size: .small)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentAlias)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette.textPrimary)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(isAnonymousMode ? ColorPalette.calmingCyan : ColorPalette.sageGreen)
                                .frame(width: 6, height: 6)

                            Text(isAnonymousMode ? "Anonymous Mode" : "Regular Mode")
                                .font(.caption2)
                                .foregroundStyle(isAnonymousMode ? ColorPalette.calmingCyan : ColorPalette.sageGreen)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                showingProfile = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "person.crop.circle")
                        .font(.caption)
                    Text("My Profile")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ColorPalette.elevatedCard)
                .foregroundStyle(ColorPalette.calmingCyan)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(ColorPalette.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button(action: onSignOut) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.caption)
                    Text("Sign Out")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ColorPalette.elevatedCard)
                .foregroundStyle(ColorPalette.textSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(ColorPalette.cardBorder, lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Tab 1: Discover & Match View
public struct DiscoverAndMatchView: View {
    public let selectedCategory: StruggleCategory?
    public let selectedTier: PricingTier?
    public let coachService: CoachServiceProtocol
    public let profileService: ProfileServiceProtocol
    public let isAnonymousMode: Bool

    @StateObject private var viewModel: CoachDiscoveryViewModel
    @State private var isBlindMatchExpanded: Bool = false
    @State public var selectedCoachForProfile: Coach? = nil

    public var coaches: [Coach] {
        viewModel.coaches.isEmpty ? MockCoachService.defaultCoaches : viewModel.coaches
    }

    public var filteredCoaches: [Coach] {
        viewModel.filteredCoaches
    }

    public init(
        initialCategory: StruggleCategory? = nil,
        initialTier: PricingTier? = nil,
        coachService: CoachServiceProtocol = MockCoachService.shared,
        profileService: ProfileServiceProtocol = UserDefaultsProfileService.shared,
        initialSelectedCoach: Coach? = nil,
        isAnonymousMode: Bool = true
    ) {
        self.selectedCategory = initialCategory
        self.selectedTier = initialTier
        self.coachService = coachService
        self.profileService = profileService
        self._selectedCoachForProfile = State(initialValue: initialSelectedCoach)
        self.isAnonymousMode = isAnonymousMode

        let initialTopic: CoachTopic?
        if let cat = initialCategory {
            switch cat {
            case .career:
                initialTopic = .careerBurnout
            case .life:
                initialTopic = .life
            case .burnout:
                initialTopic = .careerBurnout
            }
        } else {
            initialTopic = nil
        }

        _viewModel = StateObject(wrappedValue: CoachDiscoveryViewModel(
            coachService: coachService,
            initialTopic: initialTopic,
            initialTier: initialTier
        ))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Intro Banner
                headerBanner

                if isAnonymousMode {
                    // Anonymous Mode Guidance Banner
                    anonymousModeGuidanceBanner

                    // Free Match Mode: Blind Semantic Struggle Prompt Card
                    blindMatchCard
                } else {
                    // Free Match Mode: Blind Semantic Struggle Prompt Card
                    blindMatchCard

                    // Comprehensive Real-Time Filter Bar
                    filterBar

                    // Directory Results Header
                    resultsHeader

                    // Coach Cards List
                    if viewModel.filteredCoaches.isEmpty && !viewModel.isLoading {
                        emptyFilterState
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.filteredCoaches) { coach in
                                coachCard(coach)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .task {
            await viewModel.loadCoaches()
        }
        .sheet(item: $selectedCoachForProfile) { coach in
            CoachProfileView(
                coach: coach,
                coachService: coachService,
                onDismiss: {
                    selectedCoachForProfile = nil
                }
            )
        }
    }

    // MARK: - Subviews

    private var anonymousModeGuidanceBanner: some View {
        GlassCard(style: .elevated, cornerRadius: 14) {
            HStack(spacing: 12) {
                Image(systemName: "eye.slash.fill")
                    .font(.title3)
                    .foregroundStyle(ColorPalette.calmingCyan)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Anonymous Mode: Blind Matching Only")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("You will be matched automatically based on your struggle prompt. Direct coach directory browsing is hidden to eliminate choice anxiety. Switch to Regular Mode in My Profile to browse coaches.")
                        .font(.caption2)
                        .foregroundStyle(ColorPalette.textSecondary)
                        .lineSpacing(2)
                }

                Spacer()
            }
        }
    }

    private var headerBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Discover Human Coaches")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(ColorPalette.textPrimary)

            Text("All coaching is 1-on-1 audio with verified human coaches. Zero video, zero AI.")
                .font(.subheadline)
                .foregroundStyle(ColorPalette.textSecondary)
        }
    }

    // MARK: - Free Blind Match Mode
    private var blindMatchCard: some View {
        GlassCard(style: .elevated, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.subheadline)
                            .foregroundStyle(ColorPalette.calmingCyan)

                        Text("Free Blind Match Mode")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette.textPrimary)
                    }

                    Spacer()

                    TagPillView(
                        text: "Pro-Bono Guides",
                        variant: .sage
                    )
                }

                Text("Enter a brief description of what you are experiencing. Our semantic matcher pairs you blind with an available verified pro-bono coach.")
                    .font(.caption)
                    .foregroundStyle(ColorPalette.textSecondary)
                    .lineSpacing(3)

                // 14-Day Cooldown Active Banner
                if viewModel.isCooldownActive {
                    GlassCard(style: .standard, cornerRadius: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.title3)
                                .foregroundStyle(ColorPalette.calmingCyan)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("14-Day Cooldown Active")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(ColorPalette.textPrimary)

                                Text("Your next free pro-bono session unlocks in \(viewModel.cooldownDaysRemaining) days. Switch to Regular Mode in My Profile to browse coaches and schedule paid sessions.")
                                    .font(.caption2)
                                    .foregroundStyle(ColorPalette.textSecondary)
                                    .lineSpacing(2)
                            }
                        }
                    }
                }

                // 6-Session Lifetime Cap Reached Banner
                if viewModel.isLifetimeCapReached {
                    GlassCard(style: .standard, cornerRadius: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "shield.checkmark.fill")
                                .font(.title3)
                                .foregroundStyle(ColorPalette.mutedLavender)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pro-Bono Lifetime Allowance Cap (6/6) Reached")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(ColorPalette.textPrimary)

                                Text("You have completed all 6 free pro-bono sessions. Switch to Regular Mode in My Profile to browse coaches and schedule paid sessions.")
                                    .font(.caption2)
                                    .foregroundStyle(ColorPalette.textSecondary)
                                    .lineSpacing(2)
                            }
                        }
                    }
                }

                // Preferred Time Window Selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("Preferred Time Window")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textMuted)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(BlindMatchTimeWindow.allCases) { window in
                                let isSelected = viewModel.selectedTimeWindow == window
                                Button {
                                    viewModel.selectedTimeWindow = window
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: window.systemImage)
                                            .font(.caption2)
                                        Text(window.title)
                                            .font(.caption2)
                                            .fontWeight(isSelected ? .semibold : .regular)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? ColorPalette.calmingCyan.opacity(0.2) : ColorPalette.warmCharcoal)
                                    .foregroundStyle(isSelected ? ColorPalette.calmingCyan : ColorPalette.textSecondary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? ColorPalette.calmingCyan : ColorPalette.cardBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Input Field
                HStack(spacing: 8) {
                    TextField(
                        "Describe your struggle (e.g. burnout, leadership, career crossroad)...",
                        text: $viewModel.blindMatchPrompt
                    )
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(ColorPalette.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(ColorPalette.warmCharcoal)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(ColorPalette.cardBorder, lineWidth: 1)
                    )

                    AnonyButton(
                        title: viewModel.isBlindMatching ? "Matching..." : "Auto-Match",
                        systemImage: viewModel.isBlindMatching ? nil : "sparkles",
                        variant: .primary,
                        size: .small,
                        isLoading: viewModel.isBlindMatching,
                        isDisabled: viewModel.blindMatchPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || viewModel.isCooldownActive
                            || viewModel.isLifetimeCapReached
                    ) {
                        Task {
                            let profile = profileService.getProfile()
                            await viewModel.submitBlindMatch(profile: profile)
                        }
                    }
                }

                // Scheduled Session Confirmation Card
                if let session = viewModel.scheduledSession {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            TagPillView(
                                text: "Session Confirmed & Scheduled",
                                systemImage: "checkmark.circle.fill",
                                variant: .sage
                            )
                            Spacer()
                            Button("Clear") {
                                viewModel.resetBlindMatch()
                            }
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.textMuted)
                        }

                        HStack(spacing: 12) {
                            AvatarCircleView(seed: session.coachAlias, size: .small, showAura: true)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(session.coachAlias)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(ColorPalette.textPrimary)

                                    TagPillView(text: session.coachIcfLevel, variant: .lavender)
                                }

                                Text(session.topic)
                                    .font(.caption2)
                                    .foregroundStyle(ColorPalette.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            TagPillView(
                                text: "Session \(session.freeSessionsUsed) of \(session.maxFreeSessions) Free",
                                variant: .sage
                            )
                        }
                    }
                    .padding(12)
                    .background(ColorPalette.warmCharcoal.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorPalette.sageGreen.opacity(0.4), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1: Topics Filter
            VStack(alignment: .leading, spacing: 6) {
                Text("Topic Domain")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorPalette.textMuted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: "All Topics", isSelected: viewModel.selectedTopic == nil) {
                            viewModel.selectedTopic = nil
                        }

                        ForEach(CoachTopic.allCases) { topic in
                            filterChip(
                                title: topic.title,
                                systemImage: topic.systemImage,
                                isSelected: viewModel.selectedTopic == topic
                            ) {
                                viewModel.selectedTopic = (viewModel.selectedTopic == topic) ? nil : topic
                            }
                        }
                    }
                }
            }

            // Row 2: ICF Level & Free vs Paid
            HStack(alignment: .top, spacing: 12) {
                // ICF Level Filter
                VStack(alignment: .leading, spacing: 6) {
                    Text("ICF Credential")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textMuted)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            filterChip(title: "All Levels", isSelected: viewModel.selectedICFLevel == nil) {
                                viewModel.selectedICFLevel = nil
                            }

                            ForEach(ICFLevel.allCases) { level in
                                filterChip(
                                    title: level.badgeTitle,
                                    isSelected: viewModel.selectedICFLevel == level
                                ) {
                                    viewModel.selectedICFLevel = (viewModel.selectedICFLevel == level) ? nil : level
                                }
                            }
                        }
                    }
                }
            }

            // Row 3: Session Tier (Free vs Paid) & Language & Favorites
            VStack(alignment: .leading, spacing: 6) {
                Text("Session Type & Language")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorPalette.textMuted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Pricing Tier Filter
                        filterChip(title: "All Rates", isSelected: viewModel.selectedTier == nil) {
                            viewModel.selectedTier = nil
                        }

                        filterChip(
                            title: "Free Pro-Bono ($0)",
                            systemImage: "sparkles",
                            isSelected: viewModel.selectedTier == .free
                        ) {
                            viewModel.selectedTier = (viewModel.selectedTier == .free) ? nil : .free
                        }

                        filterChip(
                            title: "Certified Paid",
                            systemImage: "creditcard.fill",
                            isSelected: viewModel.selectedTier == .paid
                        ) {
                            viewModel.selectedTier = (viewModel.selectedTier == .paid) ? nil : .paid
                        }

                        Divider()
                            .frame(height: 18)
                            .background(ColorPalette.cardBorder)

                        // Language selector chips
                        filterChip(title: "All Languages", isSelected: viewModel.selectedLanguage == nil) {
                            viewModel.selectedLanguage = nil
                        }

                        let popularLanguages = ["English", "Spanish", "French", "German", "Mandarin"]
                        ForEach(popularLanguages, id: \.self) { lang in
                            filterChip(
                                title: lang,
                                isSelected: viewModel.selectedLanguage == lang
                            ) {
                                viewModel.selectedLanguage = (viewModel.selectedLanguage == lang) ? nil : lang
                            }
                        }

                        Divider()
                            .frame(height: 18)
                            .background(ColorPalette.cardBorder)

                        // Favorites Filter
                        filterChip(
                            title: viewModel.favoriteIds.isEmpty ? "Favorites" : "Favorites (\(viewModel.favoriteIds.count))",
                            systemImage: viewModel.showFavoritesOnly ? "heart.fill" : "heart",
                            isSelected: viewModel.showFavoritesOnly
                        ) {
                            viewModel.showFavoritesOnly.toggle()
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var resultsHeader: some View {
        HStack {
            Text("\(viewModel.filteredCoaches.count) Verified Coaches")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(ColorPalette.textSecondary)

            Spacer()

            if viewModel.selectedTopic != nil || viewModel.selectedICFLevel != nil || viewModel.selectedTier != nil || viewModel.selectedLanguage != nil || viewModel.showFavoritesOnly {
                Button("Reset Filters") {
                    viewModel.selectedTopic = nil
                    viewModel.selectedICFLevel = nil
                    viewModel.selectedTier = nil
                    viewModel.selectedLanguage = nil
                    viewModel.showFavoritesOnly = false
                }
                .font(.caption2)
                .foregroundStyle(ColorPalette.calmingCyan)
            }
        }
    }

    private var emptyFilterState: some View {
        GlassCard(style: .standard, cornerRadius: 16) {
            VStack(spacing: 12) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.largeTitle)
                    .foregroundStyle(ColorPalette.textMuted)

                Text("No coaches match this filter combination")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorPalette.textPrimary)

                Text("Try loosening your topic, ICF credential, or language criteria.")
                    .font(.caption)
                    .foregroundStyle(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)

                AnonyButton(
                    title: "Reset All Filters",
                    systemImage: "arrow.counterclockwise",
                    variant: .secondary,
                    size: .small
                ) {
                    viewModel.selectedTopic = nil
                    viewModel.selectedICFLevel = nil
                    viewModel.selectedTier = nil
                    viewModel.selectedLanguage = nil
                    viewModel.showFavoritesOnly = false
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    private func filterChip(
        title: String,
        systemImage: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.caption2)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? ColorPalette.calmingCyan.opacity(0.2) : ColorPalette.elevatedCard)
            .foregroundStyle(isSelected ? ColorPalette.calmingCyan : ColorPalette.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? ColorPalette.calmingCyan : ColorPalette.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func coachCard(_ coach: Coach) -> some View {
        let isFavorite = viewModel.isFavorite(coach.id)

        return GlassCard(style: .standard, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                // Coach Profile Header Row
                HStack(spacing: 12) {
                    AvatarCircleView(seed: coach.avatarSeed, size: .medium, showAura: true)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(coach.alias)
                                .font(.headline)
                                .foregroundStyle(ColorPalette.textPrimary)

                            TagPillView(
                                text: "Verified Human",
                                systemImage: "checkmark.seal.fill",
                                variant: .sage
                            )
                        }

                        Text(coach.title)
                            .font(.caption)
                            .foregroundStyle(ColorPalette.textSecondary)
                    }

                    Spacer()

                    // Favorite Toggle Button (Tapping persists status in real time)
                    Button {
                        Task {
                            await viewModel.toggleFavorite(for: coach.id)
                        }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundStyle(isFavorite ? ColorPalette.mutedLavender : ColorPalette.textMuted)
                            .padding(8)
                            .background(ColorPalette.warmCharcoal)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                // Badges Row: ICF Badge, Rate, Rating & Topic
                HStack(spacing: 8) {
                    // ICF Badge
                    TagPillView(
                        text: coach.icfLevel.badgeTitle,
                        systemImage: "award.fill",
                        variant: .lavender
                    )

                    // Hourly Rate Badge
                    if coach.tier == .free {
                        TagPillView(
                            text: "Free Pro-Bono",
                            systemImage: "sparkles",
                            variant: .sage
                        )
                    } else {
                        TagPillView(
                            text: "$\(coach.hourlyRate)/hr",
                            systemImage: "creditcard.fill",
                            variant: .cyan
                        )
                    }

                    Spacer()

                    // Rating Pill
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.sageGreen)
                        Text(String(format: "%.2f", coach.rating))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorPalette.warmCharcoal)
                    .clipShape(Capsule())
                }

                // Topic & Languages Sub-Row
                HStack(spacing: 8) {
                    TagPillView(
                        text: coach.topic.title,
                        systemImage: coach.topic.systemImage,
                        variant: .cyan
                    )

                    TagPillView(
                        text: coach.languages.joined(separator: ", "),
                        systemImage: "globe",
                        variant: .neutral
                    )

                    Spacer()

                    Text("\(coach.sessionCount) sessions")
                        .font(.caption2)
                        .foregroundStyle(ColorPalette.textMuted)
                }

                // Available Slots Quick View
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Audio Slots:")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textMuted)

                    HStack(spacing: 6) {
                        ForEach(coach.availableSlots, id: \.self) { slot in
                            Text(slot)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ColorPalette.warmCharcoal)
                                .foregroundStyle(ColorPalette.calmingCyan)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }

                AnonyButton(
                    title: "View Profile & Book",
                    systemImage: "calendar.badge.clock",
                    variant: .secondary,
                    size: .small
                ) {
                    selectedCoachForProfile = coach
                }
            }
        }
    }
}

// MARK: - Tab 2: Muse Voice Guide (Educational Primer Only)
public struct MuseVoiceGuideCompanionView: View {
    @State private var isPlayingTrack: Bool = false
    @State private var selectedTrackIndex: Int = 0

    public init() {}

    public let educationalTracks = [
        ("What Coaching Is & Is Not", "1m 20s", "Clarify goals, unblock blind spots, and learn the boundary between coaching and clinical therapy."),
        ("Preparing for Your First Human Session", "1m 45s", "What to bring, how to frame what you need, and getting comfortable in an audio-only space."),
        ("Asking Impactful Questions", "2m 10s", "How to collaborate actively with your coach toward actionable personal breakthroughs.")
    ]

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Muse Voice Guide")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("Educational audio guide explaining coaching principles and best practices. (Zero AI in coaching calls)")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Interactive Audio Primer Player
                MuseVoiceSphereView(isSpeaking: $isPlayingTrack, diameter: 140)
                    .padding(.vertical, 12)

                Text(isPlayingTrack ? "Playing: \(educationalTracks[selectedTrackIndex].0)" : "Tap sphere to listen to educational track")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isPlayingTrack ? ColorPalette.sageGreen : ColorPalette.textMuted)

                // Educational Audio Modules
                VStack(alignment: .leading, spacing: 12) {
                    Text("Coaching Educational Audio Tracks")
                        .font(.headline)
                        .foregroundStyle(ColorPalette.textPrimary)

                    ForEach(educationalTracks.indices, id: \.self) { index in
                        let track = educationalTracks[index]
                        let isCurrent = selectedTrackIndex == index

                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedTrackIndex = index
                                isPlayingTrack = true
                            }
                        }) {
                            GlassCard(
                                style: isCurrent ? .highlighted(ColorPalette.calmingCyan) : .standard,
                                cornerRadius: 14
                            ) {
                                HStack(spacing: 14) {
                                    Image(systemName: isCurrent && isPlayingTrack ? "speaker.wave.3.fill" : "play.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(isCurrent ? ColorPalette.calmingCyan : ColorPalette.textMuted)

                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack {
                                            Text(track.0)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(ColorPalette.textPrimary)

                                            Spacer()

                                            Text(track.1)
                                                .font(.caption2)
                                                .foregroundStyle(ColorPalette.calmingCyan)
                                        }

                                        Text(track.2)
                                            .font(.caption)
                                            .foregroundStyle(ColorPalette.textSecondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Tab 3: My Sessions View
public struct MySessionsView: View {
    public let preferences: OnboardingPreferences?
    public var sessions: [CoachingSession]

    public init(preferences: OnboardingPreferences? = nil) {
        self.preferences = preferences

        // Synthesize scheduled session if client completed onboarding
        if let prefs = preferences {
            self.sessions = [
                CoachingSession(
                    coachAlias: prefs.selectedCoachAlias ?? "EchoClaritas",
                    coachAvatarSeed: prefs.selectedCoachAlias ?? "EchoClaritas",
                    category: prefs.struggleCategory,
                    tier: prefs.pricingTier,
                    scheduledDate: prefs.scheduledDate,
                    timeSlot: prefs.timeSlot,
                    timeZoneIdentifier: prefs.timeZoneIdentifier,
                    status: .confirmed
                )
            ]
        } else {
            self.sessions = []
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("My Sessions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("All scheduled 1-on-1 audio calls with your verified human coach.")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                if sessions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 14) {
                        ForEach(sessions) { session in
                            sessionCard(session)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
    }

    private var emptyState: some View {
        GlassCard(style: .standard, cornerRadius: 16) {
            VStack(spacing: 14) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 36))
                    .foregroundStyle(ColorPalette.textMuted)

                Text("No Upcoming Sessions")
                    .font(.headline)
                    .foregroundStyle(ColorPalette.textPrimary)

                Text("Explore the Discover tab to connect with verified human coaches.")
                    .font(.footnote)
                    .foregroundStyle(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    private func sessionCard(_ session: CoachingSession) -> some View {
        GlassCard(style: .elevated, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    AvatarCircleView(seed: session.coachAvatarSeed, size: .medium)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(session.coachAlias)
                                .font(.headline)
                                .foregroundStyle(ColorPalette.textPrimary)

                            TagPillView(
                                text: "Verified Human Guide",
                                systemImage: "checkmark.seal.fill",
                                variant: .sage
                            )
                        }

                        Text("1-on-1 Confidential Audio")
                            .font(.caption)
                            .foregroundStyle(ColorPalette.textSecondary)
                    }

                    Spacer()

                    TagPillView(
                        text: "Confirmed",
                        systemImage: "checkmark.circle.fill",
                        variant: .sage
                    )
                }

                Divider()
                    .background(ColorPalette.cardBorder)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scheduled For")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.textMuted)

                        Text("\(formattedDate(session.scheduledDate)) at \(session.timeSlot)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(ColorPalette.textPrimary)

                        Text(session.timeZoneIdentifier)
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.calmingCyan)
                    }

                    Spacer()

                    TagPillView(
                        text: session.category.title,
                        systemImage: session.category.systemImage,
                        variant: .cyan
                    )
                }

                AnonyButton(
                    title: "Join 1-on-1 Audio Call",
                    systemImage: "phone.fill",
                    variant: .primary,
                    size: .medium
                ) {
                    // Audio call entry
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
