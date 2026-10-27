import SwiftUI

/// 3-Tab Main Shell for authenticated clients:
/// - Discover & Match: Curated anonymous coaches filtered by preferences
/// - Muse Voice Guide: Interactive audio companion for daily reflections
/// - My Sessions: Scheduled anonymous audio sanctuary sessions
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
            ColorPalette.sanctuaryGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Sanctuary Header
                sanctuaryHeader
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

    private var sanctuaryHeader: some View {
        HStack(spacing: 12) {
            AvatarCircleView(seed: userAlias ?? "SanctuaryUser", size: .small)

            VStack(alignment: .leading, spacing: 2) {
                Text(userAlias ?? "Anonymous Client")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorPalette.textPrimary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(ColorPalette.sageGreen)
                        .frame(width: 6, height: 6)

                    Text("Safe Sanctuary Active")
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
            avatarSeed: "AuraGuide"
        ),
        Coach(
            alias: "EchoClaritas",
            title: "Executive & Career Navigation",
            specialty: .career,
            tier: .paid,
            rating: 4.98,
            sessionCount: 312,
            avatarSeed: "EchoClaritas"
        ),
        Coach(
            alias: "ZephyrMind",
            title: "Life Alignment & Transitions",
            specialty: .life,
            tier: .free,
            rating: 4.91,
            sessionCount: 97,
            avatarSeed: "ZephyrMind"
        ),
        Coach(
            alias: "SolaceVessel",
            title: "Deep Stress & Boundary Restoration",
            specialty: .burnout,
            tier: .paid,
            rating: 4.99,
            sessionCount: 420,
            avatarSeed: "SolaceVessel"
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
                    Text("Discover Guides")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("All coaches operate under strict zero-PII audio agreements.")
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
                        Text(coach.alias)
                            .font(.headline)
                            .foregroundStyle(ColorPalette.textPrimary)

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

                AnonyButton(
                    title: "Connect Audio Session",
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

// MARK: - Tab 2: Muse Voice Guide Companion View
public struct MuseVoiceGuideCompanionView: View {
    @State private var isSpeaking: Bool = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Muse Companion")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("Your zero-pressure conversational AI voice guide for clarity and grounded breath.")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Interactive Sphere
                MuseVoiceSphereView(isSpeaking: $isSpeaking, diameter: 150)
                    .padding(.vertical, 16)

                Text(isSpeaking ? "Muse is listening and reflecting..." : "Tap the sphere to begin an audio reflection")
                    .font(.caption)
                    .foregroundStyle(isSpeaking ? ColorPalette.sageGreen : ColorPalette.textMuted)

                // Reflection Prompts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sanctuary Reflections")
                        .font(.headline)
                        .foregroundStyle(ColorPalette.textPrimary)

                    reflectionTile(
                        icon: "wind",
                        title: "3-Minute Grounding Breath",
                        subtitle: "Calm acute nervous system overwhelm before an important decision."
                    )

                    reflectionTile(
                        icon: "lightbulb.fill",
                        title: "Deconstruct Imposter Anxiety",
                        subtitle: "Re-anchor in factual competencies without self-criticism."
                    )

                    reflectionTile(
                        icon: "compass.drawing",
                        title: "Personal Values Compass",
                        subtitle: "Clarify what genuinely matters for your next career move."
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
    }

    private func reflectionTile(icon: String, title: String, subtitle: String) -> some View {
        GlassCard(style: .standard, cornerRadius: 14) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(ColorPalette.calmingCyan)
                    .frame(width: 36, height: 36)
                    .background(ColorPalette.calmingCyan.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(ColorPalette.textMuted)
            }
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
                    coachAlias: "SanctuaryGuide",
                    coachAvatarSeed: "SanctuaryGuide",
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

                    Text("All scheduled audio sessions in your local timezone.")
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

                Text("Explore the Discover tab to connect with verified anonymous coaches.")
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
                        Text(session.coachAlias)
                            .font(.headline)
                            .foregroundStyle(ColorPalette.textPrimary)

                        Text("Anonymous Audio Guide")
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
                    title: "Enter Safe Audio Sanctuary",
                    systemImage: "lock.shield.fill",
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
