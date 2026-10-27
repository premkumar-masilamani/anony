import SwiftUI

/// Screen displayed when a coach has registered but is_verified is false (Issue #2, Issue #17).
public struct CoachVerificationPendingView: View {
    public let coachEmail: String?
    private let authService: AuthServiceProtocol
    private let onVerified: () -> Void
    private let onSignOut: () -> Void

    @State private var isChecking: Bool = false
    @State private var statusMessage: String? = nil

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
    }

    public var body: some View {
        ZStack {
            ColorPalette.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Pulsing pending indicator
                ZStack {
                    PulsingAuraView(
                        color: ColorPalette.mutedLavender,
                        diameter: 160,
                        cycleDuration: 3.5,
                        scaleRange: 0.95...1.1
                    )

                    Circle()
                        .fill(ColorPalette.elevatedCard)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Circle()
                                .stroke(ColorPalette.cardBorder, lineWidth: 1.5)
                        )

                    Image(systemName: "hourglass.badge.eye")
                        .font(.system(size: 38))
                        .foregroundColor(ColorPalette.calmingCyan)
                }

                // Heading & Status
                VStack(spacing: 12) {
                    Text("Verification Pending")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorPalette.textPrimary)

                    Text("Your ICF credentials have been submitted and default to unverified state (is_verified: false).")
                        .font(.subheadline)
                        .foregroundColor(ColorPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Card with demo verification instructions (Issue #2 AC)
                GlassCard(style: .elevated, cornerRadius: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "terminal.fill")
                                .foregroundColor(ColorPalette.sageGreen)
                            Text("Hackathon Demo Verification")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorPalette.sageGreen)
                        }

                        Text("To verify this coach profile in the database, execute:")
                            .font(.caption2)
                            .foregroundColor(ColorPalette.textSecondary)

                        let targetEmail = coachEmail ?? "coach@example.com"
                        Text("UPDATE coaches SET is_verified = true WHERE email = '\(targetEmail)';")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(ColorPalette.calmingCyan)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ColorPalette.midnightSlate)
                            .cornerRadius(8)
                    }
                    .padding(16)
                }
                .padding(.horizontal, 24)

                if let message = statusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(ColorPalette.textMuted)
                }

                // Action buttons
                VStack(spacing: 12) {
                    AnonyButton(
                        title: "Check Verification Status",
                        systemImage: "arrow.clockwise",
                        variant: .primary,
                        size: .large,
                        isLoading: isChecking
                    ) {
                        checkStatus()
                    }

                    Button(action: onSignOut) {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.footnote)
                        .foregroundColor(ColorPalette.textMuted)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            checkStatus()
        }
    }

    private func checkStatus() {
        isChecking = true
        statusMessage = "Querying GET /api/v1/coaches/me..."

        Task { @MainActor in
            do {
                let profile = try await authService.fetchCoachProfile()
                isChecking = false
                if profile.isVerified {
                    statusMessage = "Profile is verified! Loading dashboard..."
                    onVerified()
                } else {
                    statusMessage = "Profile status: is_verified is still false."
                }
            } catch {
                isChecking = false
                statusMessage = "Could not check status: \(error.localizedDescription)"
            }
        }
    }
}
