import SwiftUI

/// Screen displayed when a coach has registered but is awaiting verification review.
/// Displays submitted credentials, 'Under Review' status indicator, supports pull-to-refresh and polling
/// against `GET /api/v1/coaches/me`, and allows editing/resubmitting anytime (Issue #2, Issue #17, Issue #18).
public struct CoachVerificationPendingView: View {
    public let coachEmail: String?
    private let authService: AuthServiceProtocol
    private let onVerified: () -> Void
    private let onSignOut: () -> Void

    @StateObject private var viewModel: CoachVerificationViewModel
    @State private var isEditSheetPresented: Bool = false

    public init(
        coachEmail: String? = nil,
        authService: AuthServiceProtocol = RemoteAuthService(),
        onVerified: @escaping () -> Void,
        onSignOut: @escaping () -> Void
    ) {
        self.coachEmail = coachEmail
        self.authService = authService
        self.onVerified = onVerified
        self.onSignOut = onSignOut
        self._viewModel = StateObject(
            wrappedValue: CoachVerificationViewModel(
                authService: authService,
                onVerified: onVerified
            )
        )
    }

    public var body: some View {
        ZStack {
            ColorPalette.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 12)

                    // Calming Aura Pending Indicator
                    ZStack {
                        PulsingAuraView(
                            color: ColorPalette.sageGreen,
                            diameter: 130,
                            cycleDuration: 3.5,
                            scaleRange: 0.95...1.1
                        )

                        Circle()
                            .fill(ColorPalette.elevatedCard)
                            .frame(width: 76, height: 76)
                            .overlay(
                                Circle()
                                    .stroke(ColorPalette.cardBorder, lineWidth: 1.5)
                            )

                        Image(systemName: "hourglass.badge.eye")
                            .font(.system(size: 32))
                            .foregroundColor(ColorPalette.sageGreen)
                    }

                    // Heading & Respectful Zero-Anxiety Copy
                    VStack(spacing: 10) {
                        Text("Awaiting Verification")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.textPrimary)

                        Text("Your ICF credentials and coach profile have been submitted and are currently awaiting review by our verification team.")
                            .font(.subheadline)
                            .foregroundColor(ColorPalette.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        // Status Pill ('Under Review' indicator per Issue #18)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(ColorPalette.calmingCyan)
                                .frame(width: 8, height: 8)
                            Text("Status: \(viewModel.statusLabel)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorPalette.calmingCyan)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(ColorPalette.calmingCyan.opacity(0.12))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(ColorPalette.calmingCyan.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.top, 4)
                    }

                    // Current Credentials & Profile Card
                    if let coach = viewModel.profile {
                        GlassCard(style: .elevated, cornerRadius: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                // Coach Header
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(coach.firstName) \(coach.lastName)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(ColorPalette.textPrimary)

                                        Text(coach.email)
                                            .font(.caption)
                                            .foregroundColor(ColorPalette.textSecondary)
                                    }
                                    Spacer()

                                    if let rate = coach.hourlyRate {
                                        Text("$\(Int(rate)) / hr")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(ColorPalette.sageGreen)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(ColorPalette.sageGreen.opacity(0.15))
                                            .cornerRadius(12)
                                    }
                                }

                                Divider().background(ColorPalette.cardBorder)

                                // Active ICF Credentials Badges
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Submitted ICF Credentials")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(ColorPalette.textSecondary)

                                    HStack(spacing: 8) {
                                        if coach.icfAcc {
                                            credentialBadge(acronym: "ACC", name: "Associate Coach")
                                        }
                                        if coach.icfPcc {
                                            credentialBadge(acronym: "PCC", name: "Professional Coach")
                                        }
                                        if coach.icfMcc {
                                            credentialBadge(acronym: "MCC", name: "Master Coach")
                                        }
                                        if coach.icfActc {
                                            credentialBadge(acronym: "ACTC", name: "Team Coaching")
                                        }
                                    }
                                }

                                // Credential Details Block
                                if let details = coach.credentialDetails, !details.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Credential Details")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(ColorPalette.textSecondary)

                                        Text(details)
                                            .font(.caption)
                                            .foregroundColor(ColorPalette.textPrimary)
                                            .padding(10)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(ColorPalette.warmCharcoal)
                                            .cornerRadius(8)
                                    }
                                }

                                // Biography Block
                                if let bio = coach.biography, !bio.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Biography")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(ColorPalette.textSecondary)

                                        Text(bio)
                                            .font(.caption)
                                            .foregroundColor(ColorPalette.textPrimary)
                                            .padding(10)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(ColorPalette.warmCharcoal)
                                            .cornerRadius(8)
                                    }
                                }

                                // Domain Specializations
                                if !coach.domainCodes.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Specialties")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(ColorPalette.textSecondary)

                                        FlowLayout(spacing: 8) {
                                            ForEach(coach.domainCodes, id: \.self) { domain in
                                                Text(CoachingDomainConfig.label(forCode: domain))
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(ColorPalette.calmingCyan)
                                                    .lineLimit(1)
                                                    .fixedSize(horizontal: true, vertical: false)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(ColorPalette.calmingCyan.opacity(0.12))
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(ColorPalette.calmingCyan.opacity(0.3), lineWidth: 1)
                                                    )
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }

                                // Location & Timezone
                                HStack(spacing: 12) {
                                    if let country = coach.countryCode {
                                        HStack(spacing: 4) {
                                            Image(systemName: "globe")
                                                .font(.caption2)
                                                .foregroundColor(ColorPalette.textMuted)
                                            Text(country)
                                                .font(.caption2)
                                                .foregroundColor(ColorPalette.textMuted)
                                        }
                                    }

                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.caption2)
                                            .foregroundColor(ColorPalette.textMuted)
                                        Text(coach.timezone)
                                            .font(.caption2)
                                            .foregroundColor(ColorPalette.textMuted)
                                    }

                                    if let gender = coach.gender {
                                        HStack(spacing: 4) {
                                            Image(systemName: "person")
                                                .font(.caption2)
                                                .foregroundColor(ColorPalette.textMuted)
                                            Text(gender)
                                                .font(.caption2)
                                                .foregroundColor(ColorPalette.textMuted)
                                        }
                                    }
                                }
                            }
                            .padding(18)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Informative note about editing and pull-to-refresh
                    Text("Pull down to refresh your verification status, or edit your profile and submit updated credentials at any time.")
                        .font(.caption2)
                        .foregroundColor(ColorPalette.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if let message = viewModel.statusMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(ColorPalette.calmingCyan)
                            .padding(.horizontal, 24)
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        if let coach = viewModel.profile {
                            AnonyButton(
                                title: "Edit Profile",
                                systemImage: "pencil.line",
                                variant: .secondary,
                                size: .large
                            ) {
                                isEditSheetPresented = true
                            }
                            .sheet(isPresented: $isEditSheetPresented) {
                                CoachProfileEditView(profile: coach, authService: authService) { updated in
                                    viewModel.applyUpdatedProfile(updated)
                                }
                            }
                        } else {
                            AnonyButton(
                                title: "Edit Profile",
                                systemImage: "pencil.line",
                                variant: .secondary,
                                size: .large,
                                isDisabled: true
                            ) {}
                        }

                        AnonyButton(
                            title: "Sign Out",
                            systemImage: "rectangle.portrait.and.arrow.right",
                            variant: .primary,
                            size: .large
                        ) {
                            onSignOut()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .refreshable {
                await viewModel.checkVerificationStatus()
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.startPolling()
        }
    }

    private func credentialBadge(acronym: String, name: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 11))
                .foregroundColor(ColorPalette.sageGreen)
            Text(acronym)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ColorPalette.sageGreen.opacity(0.15))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ColorPalette.sageGreen.opacity(0.3), lineWidth: 1)
        )
    }
}
