import SwiftUI

/// 3-Tab Main Shell for authenticated clients:
/// - Discover & Match: Curated verified human coaches filtered by preferences and availability
/// - Muse Voice Guide: Educational audio guide explaining what coaching is and how to prepare
/// - My Sessions: Scheduled 1-on-1 anonymous audio calls with human coaches
public struct MainShellView: View {
    public let userAlias: String?
    public let userEmail: String?
    public let onboardingService: OnboardingServiceProtocol
    public let onSignOut: () -> Void

    @State private var selectedTab: Int = 0

    public init(
        userAlias: String? = nil,
        userEmail: String? = nil,
        onboardingService: OnboardingServiceProtocol = UserDefaultsOnboardingService.shared,
        onSignOut: @escaping () -> Void
    ) {
        self.userAlias = userAlias
        self.userEmail = userEmail
        self.onboardingService = onboardingService
        self.onSignOut = onSignOut
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
                        initialTier: preferences?.pricingTier
                    )
                    .tabItem {
                        Label("Discover & Match", systemImage: "sparkle.magnifyingglass")
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
    }

    private var clientHeader: some View {
        HStack(spacing: 12) {
            AvatarCircleView(seed: userAlias ?? "AnonymousClient", size: .small)

            VStack(alignment: .leading, spacing: 2) {
                Text(userAlias ?? "Anonymous Client")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorPalette.textPrimary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(ColorPalette.sageGreen)
                        .frame(width: 6, height: 6)

                    Text("Private Session Ready")
                        .font(.caption2)
                        .foregroundStyle(ColorPalette.sageGreen)
                }
            }

            Spacer()

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
    public var selectedCategory: StruggleCategory?
    public var selectedTier: PricingTier?

    @State private var categoryFilter: StruggleCategory?
    @State private var tierFilter: PricingTier?

    public let coaches: [Coach] = [
        Coach(
            alias: "AuraGuide",
            title: "Resilience & Burnout Recovery",
            specialty: .burnout,
            tier: .free,
            rating: 4.96,
            sessionCount: 184,
            avatarSeed: "AuraGuide",
            availableSlots: ["Today 4:30 PM", "Tomorrow 2:30 PM", "Fri 11:00 AM"]
        ),
        Coach(
            alias: "EchoClaritas",
            title: "Executive & Career Navigation",
            specialty: .career,
            tier: .paid,
            rating: 4.98,
            sessionCount: 312,
            avatarSeed: "EchoClaritas",
            availableSlots: ["Today 2:30 PM", "Tomorrow 10:00 AM", "Thu 4:00 PM"]
        ),
        Coach(
            alias: "ZephyrMind",
            title: "Life Alignment & Transitions",
            specialty: .life,
            tier: .free,
            rating: 4.91,
            sessionCount: 97,
            avatarSeed: "ZephyrMind",
            availableSlots: ["Today 2:30 PM", "Tomorrow 3:00 PM", "Fri 10:00 AM"]
        ),
        Coach(
            alias: "SolaceVessel",
            title: "Deep Stress & Boundary Restoration",
            specialty: .burnout,
            tier: .paid,
            rating: 4.99,
            sessionCount: 420,
            avatarSeed: "SolaceVessel",
            availableSlots: ["Tomorrow 2:30 PM", "Fri 2:00 PM"]
        )
    ]

    public init(initialCategory: StruggleCategory? = nil, initialTier: PricingTier? = nil) {
        self.selectedCategory = initialCategory
        self.selectedTier = initialTier
        self._categoryFilter = State(initialValue: initialCategory)
        self._tierFilter = State(initialValue: initialTier)
    }

    public var filteredCoaches: [Coach] {
        coaches.filter { coach in
            let matchesCategory = categoryFilter == nil || coach.specialty == categoryFilter
            let matchesTier = tierFilter == nil || coach.tier == tierFilter
            return matchesCategory && matchesTier
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Intro Banner
                VStack(alignment: .leading, spacing: 6) {
                    Text("Discover Human Coaches")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("All coaching is 1-on-1 audio with verified human coaches. Zero video, zero AI.")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                // Filter Pills
                VStack(spacing: 10) {
                    // Category filter row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip(title: "All Areas", isSelected: categoryFilter == nil) {
                                categoryFilter = nil
                            }

                            ForEach(StruggleCategory.allCases) { cat in
                                filterChip(title: cat.title, isSelected: categoryFilter == cat) {
                                    categoryFilter = cat
                                }
                            }
                        }
                    }

                    // Tier filter row
                    HStack(spacing: 8) {
                        filterChip(title: "All Tiers", isSelected: tierFilter == nil) {
                            tierFilter = nil
                        }

                        ForEach(PricingTier.allCases) { tier in
                            filterChip(title: tier.title, isSelected: tierFilter == tier) {
                                tierFilter = tier
                            }
                        }
                    }
                }

                // Coach Cards
                VStack(spacing: 14) {
                    ForEach(filteredCoaches) { coach in
                        coachCard(coach)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
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
        GlassCard(style: .standard, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    AvatarCircleView(seed: coach.avatarSeed, size: .medium)

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

                HStack(spacing: 8) {
                    TagPillView(
                        text: coach.specialty.title,
                        systemImage: coach.specialty.systemImage,
                        variant: .cyan
                    )

                    TagPillView(
                        text: coach.tier.title,
                        systemImage: coach.tier.systemImage,
                        variant: coach.tier == .free ? .sage : .lavender
                    )

                    Spacer()

                    Text("\(coach.sessionCount) sessions")
                        .font(.caption2)
                        .foregroundStyle(ColorPalette.textMuted)
                }

                // Available Slots Quick View
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Slots:")
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
                    title: "Book 1-on-1 Audio Call",
                    systemImage: "waveform",
                    variant: .secondary,
                    size: .small
                ) {
                    // Connect action hook
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
