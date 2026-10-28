import SwiftUI

/// Visual circular progress ring tracking the coach's mandatory 1-hour (60-minute) monthly free session pledge.
public struct FreePledgeProgressRingView: View {
    public let pledgedMinutes: Int
    public let targetMinutes: Int
    public let progress: Double
    public let isSatisfied: Bool

    public init(
        pledgedMinutes: Int,
        targetMinutes: Int = CoachAvailabilityViewModel.mandatoryMonthlyFreeMinutes,
        progress: Double,
        isSatisfied: Bool
    ) {
        self.pledgedMinutes = pledgedMinutes
        self.targetMinutes = targetMinutes
        self.progress = progress
        self.isSatisfied = isSatisfied
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(ColorPalette.cardBorder, lineWidth: 8)
                .frame(width: 76, height: 76)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(1.0, max(0.0, progress))))
                .stroke(
                    isSatisfied ? ColorPalette.sageGreen : ColorPalette.calmingCyan,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 76, height: 76)
                .animation(.easeInOut(duration: 0.45), value: progress)

            VStack(spacing: 2) {
                Text("\(pledgedMinutes)m")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isSatisfied ? ColorPalette.sageGreen : ColorPalette.textPrimary)

                Text("/ \(targetMinutes)m")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ColorPalette.textSecondary)
            }
        }
    }
}

/// Coach Availability Manager & Mandatory 1-Hour Monthly Free Session Pledge UI (Issue #20).
public struct CoachAvailabilityManagerView: View {
    @ObservedObject public var viewModel: CoachAvailabilityViewModel
    public let coachId: UUID?
    public let coachTimezoneIdentifier: String

    public init(
        viewModel: CoachAvailabilityViewModel,
        coachId: UUID? = nil,
        coachTimezoneIdentifier: String = TimeZone.current.identifier
    ) {
        self.viewModel = viewModel
        self.coachId = coachId
        self.coachTimezoneIdentifier = coachTimezoneIdentifier
    }

    private var displayTimeZone: TimeZone {
        TimeZone(identifier: coachTimezoneIdentifier) ?? .current
    }

    public var body: some View {
        VStack(spacing: 20) {
            // 1. Mandatory 1-Hour Monthly Free Pledge Progress Ring Card
            GlassCard(style: .elevated, cornerRadius: 16) {
                HStack(spacing: 16) {
                    FreePledgeProgressRingView(
                        pledgedMinutes: viewModel.pledgedFreeMinutes,
                        targetMinutes: CoachAvailabilityViewModel.mandatoryMonthlyFreeMinutes,
                        progress: viewModel.pledgeProgress,
                        isSatisfied: viewModel.isPledgeSatisfied
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("Monthly Free Session Pledge")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorPalette.textPrimary)

                            TagPillView(
                                text: viewModel.isPledgeSatisfied ? "Quota Met" : "1 Hr Required",
                                variant: viewModel.isPledgeSatisfied ? .sage : .cyan
                            )
                        }

                        Text("Commit at least 1 hour (one 60-min or two 30-min slots) of pro-bono anonymous coaching each month.")
                            .font(.caption)
                            .foregroundColor(ColorPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(viewModel.pledgeStatusSummary)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.isPledgeSatisfied ? ColorPalette.sageGreen : ColorPalette.calmingCyan)
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)
            }

            // 2. Slot Builder Card (30m/60m + 24-Hour Advance Window + Free Anonymous Session Toggle)
            GlassCard(style: .elevated, cornerRadius: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open Availability Slot")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorPalette.textPrimary)

                            Text("24-hour advance scheduling window enforced • Stored in UTC")
                                .font(.caption2)
                                .foregroundColor(ColorPalette.textSecondary)
                        }
                        Spacer()
                    }

                    Divider()
                        .background(ColorPalette.cardBorder)

                    // Date & Time Picker (>= 24h in future)
                    DatePicker(
                        "Start Date & Time",
                        selection: $viewModel.selectedStartTime,
                        in: viewModel.minimumAdvanceDate()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .font(.caption)
                    .foregroundColor(ColorPalette.textPrimary)
                    .tint(ColorPalette.calmingCyan)

                    // Duration Selector (30 min vs 60 min)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Duration")
                            .font(.caption)
                            .foregroundColor(ColorPalette.textSecondary)

                        HStack(spacing: 12) {
                            ForEach(CoachAvailabilityViewModel.supportedDurations, id: \.self) { duration in
                                let isSelected = viewModel.selectedDurationMinutes == duration
                                Button {
                                    viewModel.selectedDurationMinutes = duration
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "clock")
                                        Text("\(duration) Mins")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.caption)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundColor(isSelected ? ColorPalette.midnightSlate : ColorPalette.textPrimary)
                                    .background(isSelected ? ColorPalette.calmingCyan : ColorPalette.warmCharcoal)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isSelected ? ColorPalette.calmingCyan : ColorPalette.cardBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Mandatory Toggle: [Offer as Free Anonymous Session]
                    Toggle(isOn: $viewModel.offerAsFreeAnonymousSession) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Offer as Free Anonymous Session")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorPalette.textPrimary)

                            Text("Counts toward your mandatory 60-minute monthly free pledge")
                                .font(.caption2)
                                .foregroundColor(ColorPalette.textSecondary)
                        }
                    }
                    .tint(ColorPalette.sageGreen)
                    .padding(12)
                    .background(ColorPalette.warmCharcoal)
                    .cornerRadius(10)

                    AnonyButton(
                        title: "Add Slot to Schedule",
                        variant: .secondary,
                        size: .medium
                    ) {
                        _ = viewModel.addDraftSlot()
                    }
                }
                .padding(16)
            }

            // 3. Feedback Banner (Zero-Anxiety Gentle Messaging)
            if let errorMessage = viewModel.errorMessage {
                GlassCard(style: .standard, cornerRadius: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(ColorPalette.mutedLavender)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(ColorPalette.textPrimary)
                        Spacer()
                    }
                    .padding(12)
                }
            }

            if let statusMessage = viewModel.statusMessage {
                GlassCard(style: .standard, cornerRadius: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ColorPalette.sageGreen)
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(ColorPalette.sageGreen)
                        Spacer()
                    }
                    .padding(12)
                }
            }

            // 4. Drafted Slots Pending Submission + Publish Button
            GlassCard(style: .elevated, cornerRadius: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Drafted Slots (\(viewModel.draftedSlots.count))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorPalette.textPrimary)
                        Spacer()
                        if !viewModel.publishedSlots.isEmpty {
                            TagPillView(text: "\(viewModel.publishedSlots.count) Published", variant: .sage)
                        }
                    }

                    if viewModel.draftedSlots.isEmpty && viewModel.publishedSlots.isEmpty {
                        Text("No slots added yet. Add 30-min or 60-min slots above and allocate at least 1 hour to your Free Anonymous Session pledge.")
                            .font(.caption)
                            .foregroundColor(ColorPalette.textSecondary)
                    } else {
                        ForEach(viewModel.draftedSlots) { slot in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(slot.formattedDate(in: displayTimeZone))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(ColorPalette.textPrimary)

                                    Text("\(slot.formattedTimeRange(in: displayTimeZone)) • \(slot.durationMinutes)m")
                                        .font(.caption2)
                                        .foregroundColor(ColorPalette.textSecondary)
                                }

                                Spacer()

                                TagPillView(
                                    text: slot.isFreePledge ? "Free Pledge" : "Standard",
                                    variant: slot.isFreePledge ? .sage : .cyan
                                )

                                Button {
                                    viewModel.removeDraftSlot(id: slot.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(ColorPalette.textMuted)
                                        .padding(6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .background(ColorPalette.warmCharcoal)
                            .cornerRadius(10)
                        }

                        if !viewModel.publishedSlots.isEmpty {
                            Divider()
                                .background(ColorPalette.cardBorder)

                            Text("Published Upcoming Slots")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorPalette.textSecondary)

                            ForEach(viewModel.publishedSlots) { publishedSlot in
                                let displayPayload = CoachAvailabilitySlotPayload(
                                    id: publishedSlot.slotId,
                                    startAt: publishedSlot.startAt,
                                    endAt: publishedSlot.endAt,
                                    durationMinutes: publishedSlot.durationMinutes,
                                    isFreePledge: publishedSlot.isFreePledge
                                )
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(displayPayload.formattedDate(in: displayTimeZone))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(ColorPalette.textPrimary)

                                        Text("\(displayPayload.formattedTimeRange(in: displayTimeZone)) • \(publishedSlot.durationMinutes)m")
                                            .font(.caption2)
                                            .foregroundColor(ColorPalette.textSecondary)
                                    }

                                    Spacer()

                                    TagPillView(
                                        text: publishedSlot.isFreePledge ? "Free Pledge" : "Standard",
                                        variant: publishedSlot.isFreePledge ? .sage : .cyan
                                    )
                                }
                                .padding(10)
                                .background(ColorPalette.warmCharcoal.opacity(0.6))
                                .cornerRadius(10)
                            }
                        }
                    }

                    AnonyButton(
                        title: viewModel.isSubmitting ? "Publishing Availability..." : "Publish Availability Calendar",
                        variant: .primary,
                        size: .large,
                        isDisabled: !viewModel.canSubmitAvailabilities
                    ) {
                        Task { @MainActor in
                            _ = await viewModel.submitAvailabilities()
                        }
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            if let id = coachId, viewModel.publishedSlots.isEmpty {
                Task { @MainActor in
                    await viewModel.loadPublishedAvailabilities(coachId: id)
                }
            }
        }
    }
}
