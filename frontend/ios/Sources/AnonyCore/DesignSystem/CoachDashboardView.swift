import SwiftUI

/// 3-Screen Coach Dashboard Shell for verified coaches (Issue #19 / K3):
/// - Screen 1: Availability & Free Pledge (`[Availability & Free Pledge]`)
/// - Screen 2: Upcoming Sessions Calendar (`[Upcoming Sessions Calendar]`)
/// - Screen 3: Profile & Earnings Summary (`[Profile & Earnings Summary]`)
public struct CoachDashboardView: View {
    public enum DashboardTab: Int, CaseIterable, Identifiable, Sendable {
        case availability = 0
        case sessions = 1
        case profile = 2

        public var id: Int { rawValue }

        public var title: String {
            switch self {
            case .availability:
                return "Availability & Free Pledge"
            case .sessions:
                return "Upcoming Sessions Calendar"
            case .profile:
                return "Profile & Earnings Summary"
            }
        }

        public var shortTabTitle: String {
            switch self {
            case .availability:
                return "Availability"
            case .sessions:
                return "Calendar"
            case .profile:
                return "Profile & Earnings"
            }
        }

        public var subtitle: String {
            switch self {
            case .availability:
                return "Manage your weekly availability slots and mandatory 60-minute monthly pro-bono pledge."
            case .sessions:
                return "View your scheduled 1-on-1 anonymous audio coaching sessions in your local timezone."
            case .profile:
                return "Track your verified ICF credentials, specializations, and net coaching earnings."
            }
        }

        public var systemImage: String {
            switch self {
            case .availability:
                return "clock.badge.checkmark"
            case .sessions:
                return "calendar.badge.clock"
            case .profile:
                return "person.text.rectangle"
            }
        }
    }

    public struct EarningsSummarySnapshot: Equatable, Sendable {
        public let completedPaidSessions: Int
        public let hourlyRate: Double
        public let grossBookings: Double
        public let platformFee: Double
        public let netPayable: Double

        public init(completedPaidSessions: Int, hourlyRate: Double) {
            self.completedPaidSessions = max(0, completedPaidSessions)
            self.hourlyRate = max(0, hourlyRate)
            let gross = Double(self.completedPaidSessions) * self.hourlyRate
            let fee = (gross * 0.10 * 100).rounded() / 100
            let net = gross - fee
            self.grossBookings = gross
            self.platformFee = fee
            self.netPayable = net
        }

        public var formattedGrossBookings: String {
            String(format: "$%.2f", grossBookings)
        }

        public var formattedPlatformFee: String {
            String(format: "-$%.2f", platformFee)
        }

        public var formattedNetPayable: String {
            String(format: "$%.2f", netPayable)
        }
    }

    public let coachEmail: String?
    public let initialTab: DashboardTab
    public let onSignOut: () -> Void
    private let authService: AuthServiceProtocol

    @State private var selectedTab: DashboardTab
    @State private var coachProfile: CoachProfileResponse?
    @State private var isLoading: Bool
    @State private var errorMessage: String? = nil
    @State private var showingEditProfile: Bool = false
    @StateObject private var availabilityViewModel: CoachAvailabilityViewModel

    public init(
        coachEmail: String? = nil,
        initialTab: DashboardTab = .availability,
        initialProfile: CoachProfileResponse? = nil,
        authService: AuthServiceProtocol = RemoteAuthService(),
        onSignOut: @escaping () -> Void
    ) {
        self.coachEmail = coachEmail
        self.initialTab = initialTab
        self.authService = authService
        self.onSignOut = onSignOut
        self._selectedTab = State(initialValue: initialTab)
        self._coachProfile = State(initialValue: initialProfile)
        self._isLoading = State(initialValue: initialProfile == nil)
        self._availabilityViewModel = StateObject(
            wrappedValue: CoachAvailabilityViewModel(authService: authService)
        )
    }

    public var body: some View {
        ZStack {
            ColorPalette.coachBackgroundGradient
                .ignoresSafeArea()

            ColorPalette.coachAuraGlowGradient
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.coachPrimaryAccent))
            } else if let profile = coachProfile {
                VStack(spacing: 0) {
                    headerBar(for: profile)

                    coachNavigationTabsBar

                    TabView(selection: $selectedTab) {
                        availabilityTab(for: profile)
                            .tabItem {
                                Label(
                                    DashboardTab.availability.shortTabTitle,
                                    systemImage: DashboardTab.availability.systemImage
                                )
                            }
                            .tag(DashboardTab.availability)

                        sessionsTab(for: profile)
                            .tabItem {
                                Label(
                                    DashboardTab.sessions.shortTabTitle,
                                    systemImage: DashboardTab.sessions.systemImage
                                )
                            }
                            .tag(DashboardTab.sessions)

                        profileTab(for: profile)
                            .tabItem {
                                Label(
                                    DashboardTab.profile.shortTabTitle,
                                    systemImage: DashboardTab.profile.systemImage
                                )
                            }
                            .tag(DashboardTab.profile)
                    }
                    .tint(ColorPalette.coachPrimaryAccent)
                }
                .sheet(isPresented: $showingEditProfile) {
                    CoachProfileEditView(
                        profile: profile,
                        authService: authService,
                        onSaved: { updatedProfile in
                            self.coachProfile = updatedProfile
                        }
                    )
                }
            } else {
                VStack(spacing: 16) {
                    Text(errorMessage ?? "Unable to load coach profile.")
                        .foregroundColor(ColorPalette.textMuted)

                    AnonyButton(title: "Sign Out", variant: .secondary, size: .medium) {
                        onSignOut()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if coachProfile == nil {
                loadProfile()
            }
        }
    }

    // MARK: - Distinct Coach Workspace Header & Clean Navigation Tabs

    private func headerBar(for profile: CoachProfileResponse) -> some View {
        HStack(spacing: 12) {
            AvatarCircleView(
                seed: "\(profile.firstName)-\(profile.lastName)",
                size: .small,
                showAura: true
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(ColorPalette.coachPrimaryAccent)
                        .frame(width: 6, height: 6)

                    Text("Verified Coach Workspace")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorPalette.coachPrimaryAccent)
                        .textCase(.uppercase)

                    TagPillView(
                        text: "ICF \(profile.icfLevel)",
                        systemImage: "checkmark.seal.fill",
                        variant: .sage
                    )
                }

                Text("\(profile.firstName) \(profile.lastName)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.textPrimary)
            }

            Spacer()

            Button(action: onSignOut) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ColorPalette.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ColorPalette.elevatedCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(ColorPalette.coachCardBorder, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var coachNavigationTabsBar: some View {
        HStack(spacing: 8) {
            ForEach(DashboardTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.caption2)
                        Text(tab.shortTabTitle)
                            .font(.caption)
                            .fontWeight(isSelected ? .semibold : .medium)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(
                        isSelected
                            ? ColorPalette.coachPrimaryAccent.opacity(0.18)
                            : ColorPalette.warmCharcoal.opacity(0.85)
                    )
                    .foregroundColor(
                        isSelected
                            ? ColorPalette.coachPrimaryAccent
                            : ColorPalette.textSecondary
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? ColorPalette.coachPrimaryAccent : ColorPalette.cardBorder,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    private func screenSectionHeader(for tab: DashboardTab) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: tab.systemImage)
                    .font(.subheadline)
                    .foregroundColor(ColorPalette.coachPrimaryAccent)

                Text(tab.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.textPrimary)
            }

            Text(tab.subtitle)
                .font(.caption)
                .foregroundColor(ColorPalette.textSecondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    // MARK: - Screen 1: Availability & Free Pledge

    private func availabilityTab(for profile: CoachProfileResponse) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                screenSectionHeader(for: .availability)

                CoachAvailabilityManagerView(
                    viewModel: availabilityViewModel,
                    coachId: profile.coachId,
                    coachTimezoneIdentifier: profile.timezone
                )
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Screen 2: Upcoming Sessions Calendar

    private func sessionsTab(for profile: CoachProfileResponse) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                screenSectionHeader(for: .sessions)

                verificationBanner(for: profile)

                GlassCard(style: .elevated, cornerRadius: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(ColorPalette.coachPrimaryAccent)
                                Text("Upcoming Sessions Calendar")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(ColorPalette.textPrimary)
                            }
                            Spacer()
                            TagPillView(text: "Live Demo Ready", variant: .sage)
                        }

                        Text("Clients booking 1-on-1 audio sessions through Anony appear here with their anonymous alias, abstract avatar, and struggle essence.")
                            .font(.caption)
                            .foregroundColor(ColorPalette.textSecondary)
                            .lineSpacing(2)

                        Divider()
                            .background(ColorPalette.cardBorder)

                        HStack {
                            Label(profile.timezone, systemImage: "globe")
                                .font(.caption2)
                                .foregroundColor(ColorPalette.textMuted)
                            Spacer()
                            Text("Safe Room unlocks 10m before start")
                                .font(.caption2)
                                .foregroundColor(ColorPalette.coachSecondaryAccent)
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Screen 3: Profile & Earnings Summary

    private func profileTab(for profile: CoachProfileResponse) -> some View {
        let earnings = EarningsSummarySnapshot(
            completedPaidSessions: 0,
            hourlyRate: profile.hourlyRate ?? 150.0
        )

        return ScrollView {
            VStack(spacing: 18) {
                screenSectionHeader(for: .profile)

                earningsSummaryCard(for: profile, earnings: earnings)

                verificationBanner(for: profile)

                profileInformationCard(for: profile)
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private func earningsSummaryCard(
        for profile: CoachProfileResponse,
        earnings: EarningsSummarySnapshot
    ) -> some View {
        GlassCard(style: .elevated, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(ColorPalette.coachPrimaryAccent)
                        Text("Earnings Summary")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorPalette.textPrimary)
                    }
                    Spacer()
                    TagPillView(text: "90% Coach Share", variant: .sage)
                }

                Divider()
                    .background(ColorPalette.cardBorder)

                HStack {
                    Text("Standard Hourly Rate")
                        .font(.caption)
                        .foregroundColor(ColorPalette.textSecondary)
                    Spacer()
                    Text("$\(Int(profile.hourlyRate ?? 150.0))/hr")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.textPrimary)
                }

                HStack {
                    Text("Gross Bookings")
                        .font(.caption)
                        .foregroundColor(ColorPalette.textSecondary)
                    Spacer()
                    Text(earnings.formattedGrossBookings)
                        .font(.caption)
                        .foregroundColor(ColorPalette.textPrimary)
                }

                HStack {
                    Text("Platform Fee (10%)")
                        .font(.caption)
                        .foregroundColor(ColorPalette.textSecondary)
                    Spacer()
                    Text(earnings.formattedPlatformFee)
                        .font(.caption)
                        .foregroundColor(ColorPalette.coachSecondaryAccent)
                }

                Divider()
                    .background(ColorPalette.cardBorder)

                HStack {
                    Text("Net Payable Balance")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.textPrimary)
                    Spacer()
                    Text(earnings.formattedNetPayable)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(ColorPalette.coachPrimaryAccent)
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }

    private func profileInformationCard(for profile: CoachProfileResponse) -> some View {
        GlassCard(style: .elevated, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Profile Information")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.textPrimary)

                    Spacer()

                    Button {
                        showingEditProfile = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Edit Profile")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(ColorPalette.coachPrimaryAccent)
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .background(ColorPalette.cardBorder)

                HStack {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(ColorPalette.textSecondary)
                    Spacer()
                    Text(profile.email)
                        .font(.caption)
                        .foregroundColor(ColorPalette.textPrimary)
                }

                HStack {
                    Text("Timezone")
                        .font(.caption)
                        .foregroundColor(ColorPalette.textSecondary)
                    Spacer()
                    Text(profile.timezone)
                        .font(.caption)
                        .foregroundColor(ColorPalette.textPrimary)
                }

                if let biography = profile.biography, !biography.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Biography")
                            .font(.caption)
                            .foregroundColor(ColorPalette.textSecondary)
                        Text(biography)
                            .font(.caption)
                            .foregroundColor(ColorPalette.textPrimary)
                            .lineSpacing(2)
                    }
                }

                if !profile.domainCodes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Specializations")
                            .font(.caption)
                            .foregroundColor(ColorPalette.textSecondary)

                        FlowLayout(spacing: 8) {
                            ForEach(profile.domainCodes, id: \.self) { domain in
                                TagPillView(
                                    text: CoachingDomainConfig.label(forCode: domain),
                                    variant: .sage
                                )
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }

    private func verificationBanner(for profile: CoachProfileResponse) -> some View {
        GlassCard(style: .elevated, cornerRadius: 16) {
            HStack(spacing: 16) {
                Circle()
                    .fill(ColorPalette.coachPrimaryAccent.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ColorPalette.coachPrimaryAccent)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Verified ICF Coach")
                            .font(.headline)
                            .foregroundColor(ColorPalette.textPrimary)

                        TagPillView(text: profile.icfLevel, variant: .lavender)
                    }

                    Text(profile.credentialDetails ?? "ICF Professional Credential")
                        .font(.caption)
                        .foregroundColor(ColorPalette.textSecondary)
                }
                Spacer()
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }

    private func loadProfile() {
        isLoading = true
        Task { @MainActor in
            do {
                let profile = try await authService.fetchCoachProfile()
                self.coachProfile = profile
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
