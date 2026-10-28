import SwiftUI
import Combine

/// Coach Upcoming Sessions View presenting confirmed sessions with zero client identity
/// and client struggle essence to enable unbiased session preparation.
public struct CoachUpcomingSessionsView: View {
    @ObservedObject public var viewModel: CoachUpcomingSessionsViewModel
    public let coachTimezoneIdentifier: String

    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    public init(
        viewModel: CoachUpcomingSessionsViewModel,
        coachTimezoneIdentifier: String = TimeZone.current.identifier
    ) {
        self.viewModel = viewModel
        self.coachTimezoneIdentifier = coachTimezoneIdentifier
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header: Timezone & Zero-PII Guarantee Banner
            timezoneHeaderCard

            // Active Safe Room Call Banner
            if let activeSession = viewModel.activeSession,
               case .connected(let token) = viewModel.connectionState {
                activeSafeRoomBanner(session: activeSession, token: token)
            }

            // Error banner if connection fails or attempted prematurely
            if let error = viewModel.errorMessage {
                errorMessageBanner(error)
            }

            // Sessions List or Empty State
            if viewModel.confirmedSessions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.confirmedSessions) { session in
                        sessionCard(session)
                    }
                }
            }
        }
        .onAppear {
            viewModel.updateCoachTimezone(identifier: coachTimezoneIdentifier)
        }
        .onReceive(timer) { now in
            viewModel.tick(to: now)
        }
    }

    // MARK: - Subviews

    private var timezoneHeaderCard: some View {
        GlassCard(style: .elevated, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confirmed Upcoming Sessions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorPalette.textPrimary)

                        Text("Scheduled in your local timezone (\(viewModel.coachTimeZone.identifier))")
                            .font(.caption2)
                            .foregroundColor(ColorPalette.calmingCyan)
                    }

                    Spacer()

                    TagPillView(
                        text: "Zero Client PII",
                        systemImage: "eye.slash.fill",
                        variant: .sage
                    )
                }

                Text("Client personal names, photos, and contact info are stripped before reaching your screen. Only procedural abstract avatars and sanitized struggle essence are shown.")
                    .font(.caption)
                    .foregroundColor(ColorPalette.textSecondary)
                    .lineSpacing(2)
            }
            .padding(16)
        }
    }

    private func activeSafeRoomBanner(session: CoachUpcomingSession, token: SafeRoomConnectionToken) -> some View {
        GlassCard(style: .highlighted(ColorPalette.sageGreen), cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    PulsingAuraView(color: ColorPalette.sageGreen, diameter: 28, cycleDuration: 3.5)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Safe Room Active")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorPalette.textPrimary)

                        Text("Encrypted 1-on-1 audio with \(session.clientAlias) (\(token.roomName))")
                            .font(.caption)
                            .foregroundColor(ColorPalette.textSecondary)
                    }

                    Spacer()

                    TagPillView(
                        text: "Live Audio",
                        systemImage: "waveform",
                        variant: .sage
                    )
                }

                AnonyButton(
                    title: "Leave Safe Room",
                    systemImage: "phone.down.fill",
                    variant: .secondary,
                    size: .small
                ) {
                    Task {
                        await viewModel.leaveSafeRoom()
                    }
                }
            }
            .padding(16)
        }
    }

    private func errorMessageBanner(_ message: String) -> some View {
        GlassCard(style: .standard, cornerRadius: 12) {
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(ColorPalette.mutedLavender)
                Text(message)
                    .font(.caption)
                    .foregroundColor(ColorPalette.textPrimary)
                Spacer()
            }
            .padding(12)
        }
    }

    private var emptyState: some View {
        GlassCard(style: .standard, cornerRadius: 16) {
            VStack(spacing: 14) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 36))
                    .foregroundColor(ColorPalette.textMuted)

                Text("No Confirmed Sessions Scheduled")
                    .font(.headline)
                    .foregroundColor(ColorPalette.textPrimary)

                Text("When clients book audio sessions from your availability calendar, they will appear here anonymously.")
                    .font(.footnote)
                    .foregroundColor(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
        }
    }

    private func sessionCard(_ session: CoachUpcomingSession) -> some View {
        let canStart = viewModel.canStartSession(for: session)
        let countdownText = viewModel.formattedCountdown(for: session)
        let isConnectingThisSession = viewModel.connectionState == .connecting(sessionId: session.id)

        return GlassCard(
            style: canStart ? .highlighted(ColorPalette.sageGreen) : .elevated,
            cornerRadius: 16
        ) {
            VStack(alignment: .leading, spacing: 14) {
                // Client Identity Row (Procedural Avatar + Client Alias + Zero PII Tags)
                HStack(spacing: 12) {
                    AvatarCircleView(
                        seed: session.clientAvatarSeed,
                        size: .medium,
                        showAura: canStart
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(session.clientAlias)
                                .font(.headline)
                                .foregroundColor(ColorPalette.textPrimary)

                            TagPillView(
                                text: "Anonymous Client",
                                systemImage: "shield.fill",
                                variant: .cyan
                            )
                        }

                        Text("1-on-1 Confidential Audio Coaching")
                            .font(.caption)
                            .foregroundColor(ColorPalette.textSecondary)
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

                // Client Struggle Essence Box
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundColor(ColorPalette.calmingCyan)

                        Text("Client Struggle Essence")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorPalette.textMuted)

                        Spacer()

                        TagPillView(
                            text: session.category.title,
                            systemImage: session.category.systemImage,
                            variant: .cyan
                        )
                    }

                    Text(session.struggleEssence)
                        .font(.subheadline)
                        .foregroundColor(ColorPalette.textPrimary)
                        .lineSpacing(3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ColorPalette.warmCharcoal)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ColorPalette.cardBorder, lineWidth: 1)
                        )
                }

                Divider()
                    .background(ColorPalette.cardBorder)

                // Timezone-Aware Schedule & Countdown
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scheduled (Local Time)")
                            .font(.caption2)
                            .foregroundColor(ColorPalette.textMuted)

                        Text(viewModel.formattedDate(for: session))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ColorPalette.textPrimary)

                        Text(viewModel.formattedTimeRange(for: session))
                            .font(.caption2)
                            .foregroundColor(ColorPalette.calmingCyan)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption2)
                                .foregroundColor(canStart ? ColorPalette.sageGreen : ColorPalette.calmingCyan)

                            Text(countdownText)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                                .foregroundColor(canStart ? ColorPalette.sageGreen : ColorPalette.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(ColorPalette.midnightSlate.opacity(0.65))
                        )

                        Text(canStart ? "Safe Room Ready" : "Unlocks 10m before")
                            .font(.caption2)
                            .foregroundColor(canStart ? ColorPalette.sageGreen : ColorPalette.textMuted)
                    }
                }

                // Start Session Button (enabled 10 minutes prior to session start)
                AnonyButton(
                    title: canStart ? "Start Session" : "Start Session (Opens in 10m)",
                    systemImage: canStart ? "lock.shield.fill" : "clock.badge",
                    variant: canStart ? .primary : .secondary,
                    size: .medium,
                    isLoading: isConnectingThisSession,
                    isDisabled: !canStart
                ) {
                    Task {
                        await viewModel.startSession(session)
                    }
                }
            }
            .padding(16)
        }
    }
}
