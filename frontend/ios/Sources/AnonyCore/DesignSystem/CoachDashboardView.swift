import SwiftUI

/// 3-Screen Coach Dashboard displayed for verified coaches after login or status update (Issue #18).
public struct CoachDashboardView: View {
    public enum DashboardTab: Int, CaseIterable, Sendable {
        case sessions = 0
        case availability = 1
        case profile = 2
    }

    public let coachEmail: String?
    public let onSignOut: () -> Void
    private let authService: AuthServiceProtocol

    @State private var selectedTab: DashboardTab = .sessions
    @State private var coachProfile: CoachProfileResponse?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @StateObject private var availabilityViewModel: CoachAvailabilityViewModel

    public init(
        coachEmail: String? = nil,
        authService: AuthServiceProtocol = RemoteAuthService(),
        onSignOut: @escaping () -> Void
    ) {
        self.coachEmail = coachEmail
        self.authService = authService
        self.onSignOut = onSignOut
        self._availabilityViewModel = StateObject(
            wrappedValue: CoachAvailabilityViewModel(authService: authService)
        )
    }

    public var body: some View {
        ZStack {
            ColorPalette.backgroundGradient
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.calmingCyan))
            } else if let profile = coachProfile {
                VStack(spacing: 0) {
                    headerBar(for: profile)

                    TabView(selection: $selectedTab) {
                        sessionsTab(for: profile)
                            .tabItem {
                                Label("Sessions", systemImage: "calendar.badge.clock")
                            }
                            .tag(DashboardTab.sessions)

                        availabilityTab(for: profile)
                            .tabItem {
                                Label("Availability", systemImage: "clock.badge.checkmark")
                            }
                            .tag(DashboardTab.availability)

                        profileTab(for: profile)
                            .tabItem {
                                Label("Profile", systemImage: "person.text.rectangle")
                            }
                            .tag(DashboardTab.profile)
                    }
                    .tint(ColorPalette.calmingCyan)
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
            loadProfile()
        }
    }

    private func headerBar(for profile: CoachProfileResponse) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Coach Workspace")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.calmingCyan)
                    .textCase(.uppercase)

                Text("\(profile.firstName) \(profile.lastName)")
                    .font(.title2)
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
                .foregroundColor(ColorPalette.textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ColorPalette.warmCharcoal)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private func sessionsTab(for profile: CoachProfileResponse) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                verificationBanner(for: profile)

                GlassCard(style: .elevated, cornerRadius: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Upcoming Sessions")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorPalette.textPrimary)
                            Spacer()
                            TagPillView(text: "Live Demo Ready", variant: .cyan)
                        }

                        Text("Clients booking sessions through Anony will appear here anonymously. Your private schedule is synchronized.")
                            .font(.caption)
                            .foregroundColor(ColorPalette.textSecondary)
                    }
                    .padding(16)
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private func availabilityTab(for profile: CoachProfileResponse) -> some View {
        ScrollView {
            VStack(spacing: 20) {
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

    private func profileTab(for profile: CoachProfileResponse) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                verificationBanner(for: profile)

                GlassCard(style: .elevated, cornerRadius: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Profile Information")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorPalette.textPrimary)

                        Divider()
                            .background(ColorPalette.cardBorder)

                        HStack {
                            Text("Timezone")
                                .font(.caption)
                                .foregroundColor(ColorPalette.textSecondary)
                            Spacer()
                            Text(profile.timezone)
                                .font(.caption)
                                .foregroundColor(ColorPalette.textPrimary)
                        }

                        HStack {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(ColorPalette.textSecondary)
                            Spacer()
                            Text(profile.email)
                                .font(.caption)
                                .foregroundColor(ColorPalette.textPrimary)
                        }

                        if !profile.domainCodes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Specializations")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                HStack(spacing: 8) {
                                    ForEach(profile.domainCodes, id: \.self) { domain in
                                        TagPillView(text: domain, variant: .sage)
                                    }
                                }
                            }
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

    private func verificationBanner(for profile: CoachProfileResponse) -> some View {
        GlassCard(style: .elevated, cornerRadius: 16) {
            HStack(spacing: 16) {
                Circle()
                    .fill(ColorPalette.sageGreen.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ColorPalette.sageGreen)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Verified ICF Coach")
                            .font(.headline)
                            .foregroundColor(ColorPalette.textPrimary)

                        TagPillView(text: profile.icfLevel, variant: .cyan)
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
