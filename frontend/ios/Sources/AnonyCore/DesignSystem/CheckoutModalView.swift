import SwiftUI

/// Checkout modal presented when a client taps an available time slot.
/// Provides full pricing transparency, local timezone slot clarity, and zero-anxiety confidentiality guarantees.
public struct CheckoutModalView: View {
    public let coach: Coach
    public let slot: CoachSlot
    public let clientAlias: String
    public let coachService: CoachServiceProtocol
    public let timeZone: TimeZone
    public let onConfirmed: (CoachingSession) -> Void
    public let onDismiss: () -> Void

    @State public var isBooking: Bool = false
    @State public var bookingError: String? = nil
    @State public var bookingSuccess: Bool = false

    public init(
        coach: Coach,
        slot: CoachSlot,
        clientAlias: String? = nil,
        coachService: CoachServiceProtocol = MockCoachService.shared,
        timeZone: TimeZone = .current,
        onConfirmed: @escaping (CoachingSession) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.coach = coach
        self.slot = slot
        self.clientAlias = clientAlias ?? "AnonymousClient"
        self.coachService = coachService
        self.timeZone = timeZone
        self.onConfirmed = onConfirmed
        self.onDismiss = onDismiss
    }

    public var localTimeZoneName: String {
        timeZone.localizedName(for: .generic, locale: .current) ?? timeZone.identifier
    }

    public var body: some View {
        ZStack {
            ColorPalette.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Grabber & Close Bar
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header Summary
                        summaryHeaderCard

                        // Slot & Local Timezone Card
                        slotDetailsCard

                        // Pricing Breakdown Card
                        pricingBreakdownCard

                        // Confidentiality & Privacy Assurances
                        confidentialityAssurancesCard

                        // Error Banner if booking fails
                        if let error = bookingError {
                            errorBanner(error)
                        }

                        // Action Buttons
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            Text("Confirm Session Reservation")
                .font(.headline)
                .foregroundStyle(ColorPalette.textPrimary)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(ColorPalette.textMuted)
            }
            .buttonStyle(.plain)
        }
    }

    private var summaryHeaderCard: some View {
        GlassCard(style: .elevated, cornerRadius: 16) {
            HStack(spacing: 14) {
                AvatarCircleView(seed: coach.avatarSeed, size: .large, showAura: true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(coach.alias)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(ColorPalette.textPrimary)

                        TagPillView(
                            text: coach.icfLevel.badgeTitle,
                            systemImage: "award.fill",
                            variant: .lavender
                        )
                    }

                    Text(coach.title)
                        .font(.caption)
                        .foregroundStyle(ColorPalette.textSecondary)

                    HStack(spacing: 6) {
                        TagPillView(
                            text: coach.specialty.title,
                            systemImage: coach.specialty.systemImage,
                            variant: .cyan
                        )

                        Text("Verified Human Coach")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.sageGreen)
                    }
                }

                Spacer()
            }
        }
    }

    private var slotDetailsCard: some View {
        GlassCard(style: .standard, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.calmingCyan)

                    Text("Selected Date & Time")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Spacer()

                    TagPillView(
                        text: slot.timeZoneAbbreviation(in: timeZone),
                        systemImage: "clock",
                        variant: .cyan
                    )
                }

                Divider()
                    .background(ColorPalette.cardBorder)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day & Date")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.textMuted)

                        Text(slot.formattedDate(in: timeZone))
                            .font(.headline)
                            .foregroundStyle(ColorPalette.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Session Time (\(localTimeZoneName))")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.textMuted)

                        Text(slot.formattedTime(in: timeZone))
                            .font(.headline)
                            .foregroundStyle(ColorPalette.calmingCyan)
                    }
                }

                Text("Duration: \(slot.durationMinutes) minutes · 1-on-1 audio only")
                    .font(.caption2)
                    .foregroundStyle(ColorPalette.textSecondary)
            }
        }
    }

    private var pricingBreakdownCard: some View {
        GlassCard(style: .standard, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.sageGreen)

                    Text("Pricing & Transparency")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Spacer()

                    if coach.tier == .free {
                        TagPillView(
                            text: "100% Free",
                            variant: .sage
                        )
                    } else {
                        TagPillView(
                            text: "Standard Rate",
                            variant: .cyan
                        )
                    }
                }

                Divider()
                    .background(ColorPalette.cardBorder)

                HStack {
                    Text(coach.tier == .free ? "Pro-Bono Community Coaching" : "1-on-1 Human Audio Coaching")
                        .font(.caption)
                        .foregroundStyle(ColorPalette.textSecondary)

                    Spacer()

                    if coach.tier == .free {
                        Text("$0.00")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(ColorPalette.sageGreen)
                    } else {
                        Text("$\(coach.hourlyRate).00")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(ColorPalette.textPrimary)
                    }
                }

                if coach.tier == .free {
                    Text("This pro-bono session is provided at zero cost to support your growth.")
                        .font(.caption2)
                        .foregroundStyle(ColorPalette.sageGreen)
                } else {
                    Text("Transparent hourly pricing. No subscription traps, zero hidden fees.")
                        .font(.caption2)
                        .foregroundStyle(ColorPalette.textMuted)
                }
            }
        }
    }

    private var confidentialityAssurancesCard: some View {
        GlassCard(style: .standard, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.calmingCyan)

                    Text("Sacred Client Anonymity")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textPrimary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    assuranceRow(icon: "waveform", text: "Zero Video — Pure audio connection removes visual judgment.")
                    assuranceRow(icon: "eye.slash", text: "Zero PII Shared — Coach only knows your alias (\(clientAlias)).")
                    assuranceRow(icon: "mic.slash", text: "Zero AI Listening — Private conversation between two humans.")
                }
            }
        }
    }

    private func assuranceRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(ColorPalette.calmingCyan)
                .frame(width: 14)

            Text(text)
                .font(.caption2)
                .foregroundStyle(ColorPalette.textSecondary)
                .lineSpacing(2)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .foregroundStyle(ColorPalette.textPrimary)
        }
        .padding(10)
        .background(Color.red.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            AnonyButton(
                title: coach.tier == .free ? "Confirm Free Reservation" : "Confirm & Reserve ($\(coach.hourlyRate).00)",
                systemImage: "checkmark.circle.fill",
                variant: .primary,
                size: .large,
                isLoading: isBooking
            ) {
                Task {
                    await handleReservation()
                }
            }

            Button(action: onDismiss) {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundStyle(ColorPalette.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    @discardableResult
    public func handleReservation() async -> CoachingSession? {
        isBooking = true
        bookingError = nil
        do {
            let session = try await coachService.bookSession(
                coachId: coach.id,
                slot: slot,
                clientAlias: clientAlias
            )
            isBooking = false
            bookingSuccess = true
            onConfirmed(session)
            return session
        } catch {
            isBooking = false
            bookingError = error.localizedDescription
            return nil
        }
    }
}
