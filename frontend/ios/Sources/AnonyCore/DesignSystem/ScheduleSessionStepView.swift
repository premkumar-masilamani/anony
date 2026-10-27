import SwiftUI

/// Mode for scheduling a session in Step 3.
public enum ScheduleMode: String, CaseIterable, Identifiable, Sendable {
    case byCoach = "Browse by Coach"
    case byTime = "Find by Time"

    public var id: String { rawValue }
}

/// Step 3 of the guided progressive disclosure stepper.
/// Allows clients to search by coach availability or find coaches by a selected time slot.
/// All coaching sessions are strictly 1-on-1 confidential audio calls with real human coaches.
public struct ScheduleSessionStepView: View {
    public let selectedCategory: StruggleCategory
    public let selectedTier: PricingTier
    public let onConfirm: (OnboardingPreferences) -> Void

    @State public var scheduleMode: ScheduleMode = .byCoach
    @State public var selectedCoach: Coach?
    @State public var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State public var selectedTimeSlot: String = "2:30 PM"

    public var localTimeZoneName: String {
        TimeZone.current.localizedName(for: .generic, locale: .current) ?? TimeZone.current.identifier
    }

    public let allCoaches: [Coach] = [
        Coach(
            alias: "EchoClaritas",
            title: "Career & Leadership Guide",
            specialty: .career,
            tier: .paid,
            rating: 4.98,
            sessionCount: 312,
            avatarSeed: "EchoClaritas",
            availableSlots: ["Today 2:30 PM", "Tomorrow 10:00 AM", "Thu 4:00 PM"]
        ),
        Coach(
            alias: "AuraGuide",
            title: "Executive & Burnout Guide",
            specialty: .burnout,
            tier: .free,
            rating: 4.96,
            sessionCount: 184,
            avatarSeed: "AuraGuide",
            availableSlots: ["Today 4:30 PM", "Tomorrow 2:30 PM", "Fri 11:00 AM"]
        ),
        Coach(
            alias: "ZephyrMind",
            title: "Life Alignment Specialist",
            specialty: .life,
            tier: .free,
            rating: 4.91,
            sessionCount: 97,
            avatarSeed: "ZephyrMind",
            availableSlots: ["Today 2:30 PM", "Tomorrow 3:00 PM", "Fri 10:00 AM"]
        ),
        Coach(
            alias: "SolaceVessel",
            title: "Deep Stress Restoration",
            specialty: .burnout,
            tier: .paid,
            rating: 4.99,
            sessionCount: 420,
            avatarSeed: "SolaceVessel",
            availableSlots: ["Tomorrow 2:30 PM", "Fri 2:00 PM"]
        )
    ]

    public var relevantCoaches: [Coach] {
        let matching = allCoaches.filter { $0.specialty == selectedCategory || $0.tier == selectedTier }
        return matching.isEmpty ? allCoaches : matching
    }

    public var availableTimeSlots: [String] {
        ["10:00 AM", "2:30 PM", "4:30 PM", "6:00 PM"]
    }

    public init(
        selectedCategory: StruggleCategory,
        selectedTier: PricingTier,
        initialMode: ScheduleMode = .byCoach,
        onConfirm: @escaping (OnboardingPreferences) -> Void
    ) {
        self.selectedCategory = selectedCategory
        self.selectedTier = selectedTier
        self._scheduleMode = State(initialValue: initialMode)
        self.onConfirm = onConfirm
        self._selectedCoach = State(initialValue: allCoaches.first)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Book Your 1-on-1 Audio Session")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("All sessions are strictly confidential audio with verified human coaches.")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                // Local Timezone Banner
                GlassCard(style: .standard, cornerRadius: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18))
                            .foregroundStyle(ColorPalette.calmingCyan)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Local Timezone")
                                .font(.caption2)
                                .foregroundStyle(ColorPalette.textMuted)

                            Text(localTimeZoneName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(ColorPalette.textPrimary)
                        }

                        Spacer()

                        TagPillView(
                            text: "Local Time",
                            systemImage: "antenna.radiowaves.left.and.right",
                            variant: .cyan
                        )
                    }
                }

                // Dual Mode Selector
                HStack(spacing: 8) {
                    modeButton(title: "Browse by Coach", mode: .byCoach, icon: "person.crop.circle")
                    modeButton(title: "Find by Time", mode: .byTime, icon: "clock")
                }
                .padding(4)
                .background(ColorPalette.warmCharcoal)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Mode Views
                if scheduleMode == .byCoach {
                    coachAvailabilitySection
                } else {
                    timeSlotSearchSection
                }

                // Selected Booking Summary
                if let coach = selectedCoach {
                    summaryCard(coach: coach)
                }

                // Confirm CTA
                AnonyButton(
                    title: "Confirm & Complete Setup",
                    systemImage: "checkmark.circle.fill",
                    variant: .primary,
                    size: .large,
                    isDisabled: selectedCoach == nil,
                    action: {
                        let preferences = OnboardingPreferences(
                            struggleCategory: selectedCategory,
                            pricingTier: selectedTier,
                            scheduledDate: selectedDate,
                            timeSlot: selectedTimeSlot,
                            timeZoneIdentifier: TimeZone.current.identifier,
                            selectedCoachAlias: selectedCoach?.alias
                        )
                        onConfirm(preferences)
                    }
                )
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Mode A: Browse by Coach's Availability
    private var coachAvailabilitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Select a verified coach to view their open slots:")
                .font(.footnote)
                .foregroundStyle(ColorPalette.textSecondary)

            ForEach(relevantCoaches) { coach in
                let isSelectedCoach = selectedCoach?.id == coach.id

                GlassCard(
                    style: isSelectedCoach ? .highlighted(ColorPalette.calmingCyan) : .standard,
                    cornerRadius: 16
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            AvatarCircleView(seed: coach.avatarSeed, size: .medium)

                            VStack(alignment: .leading, spacing: 2) {
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

                                Text("\(coach.title) • \(String(format: "%.2f", coach.rating)) ★")
                                    .font(.caption)
                                    .foregroundStyle(ColorPalette.textSecondary)
                            }

                            Spacer()
                        }

                        // Open slots for this coach
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Available Slots:")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(ColorPalette.textMuted)

                            HStack(spacing: 8) {
                                ForEach(coach.availableSlots, id: \.self) { slot in
                                    let isSelectedSlot = isSelectedCoach && selectedTimeSlot == slot

                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            selectedCoach = coach
                                            selectedTimeSlot = slot
                                        }
                                    }) {
                                        Text(slot)
                                            .font(.caption)
                                            .fontWeight(isSelectedSlot ? .semibold : .regular)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(isSelectedSlot ? ColorPalette.calmingCyan.opacity(0.2) : ColorPalette.warmCharcoal)
                                            .foregroundStyle(isSelectedSlot ? ColorPalette.calmingCyan : ColorPalette.textSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(isSelectedSlot ? ColorPalette.calmingCyan : ColorPalette.cardBorder, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mode B: Find by Time Slot
    private var timeSlotSearchSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pick your preferred time to see available human coaches:")
                .font(.footnote)
                .foregroundStyle(ColorPalette.textSecondary)

            // Date & Slot Controls
            VStack(spacing: 12) {
                DatePicker(
                    "Session Date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .tint(ColorPalette.calmingCyan)
                .colorScheme(.dark)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ColorPalette.elevatedCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 8) {
                    ForEach(availableTimeSlots, id: \.self) { slot in
                        let isSelected = selectedTimeSlot == slot

                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedTimeSlot = slot
                            }
                        }) {
                            Text(slot)
                                .font(.caption)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSelected ? ColorPalette.calmingCyan.opacity(0.2) : ColorPalette.elevatedCard)
                                .foregroundStyle(isSelected ? ColorPalette.calmingCyan : ColorPalette.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? ColorPalette.calmingCyan : ColorPalette.cardBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Coaches available at this time
            let coachesAvailable = relevantCoaches
            VStack(alignment: .leading, spacing: 8) {
                Text("\(coachesAvailable.count) Human Coaches Available at \(selectedTimeSlot):")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorPalette.sageGreen)

                ForEach(coachesAvailable) { coach in
                    let isSelected = selectedCoach?.id == coach.id

                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedCoach = coach
                        }
                    }) {
                        GlassCard(
                            style: isSelected ? .highlighted(ColorPalette.sageGreen) : .standard,
                            cornerRadius: 14
                        ) {
                            HStack(spacing: 12) {
                                AvatarCircleView(seed: coach.avatarSeed, size: .small)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(coach.alias)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(ColorPalette.textPrimary)

                                    Text("\(coach.specialty.title) • \(String(format: "%.2f", coach.rating)) ★")
                                        .font(.caption2)
                                        .foregroundStyle(ColorPalette.textSecondary)
                                }

                                Spacer()

                                Text(isSelected ? "Selected" : "Select")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(isSelected ? ColorPalette.sageGreen : ColorPalette.warmCharcoal)
                                    .foregroundStyle(isSelected ? ColorPalette.midnightSlate : ColorPalette.textPrimary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func modeButton(title: String, mode: ScheduleMode, icon: String) -> some View {
        let isSelected = scheduleMode == mode

        return Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                scheduleMode = mode
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? ColorPalette.calmingCyan : Color.clear)
            .foregroundStyle(isSelected ? ColorPalette.midnightSlate : ColorPalette.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func summaryCard(coach: Coach) -> some View {
        GlassCard(style: .elevated, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Coach: \(coach.alias)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette.textPrimary)

                        Text("Time: \(selectedTimeSlot) (\(localTimeZoneName))")
                            .font(.caption)
                            .foregroundStyle(ColorPalette.calmingCyan)
                    }

                    Spacer()

                    TagPillView(
                        text: "Human 1-on-1 Audio",
                        systemImage: "person.wave.2.fill",
                        variant: .sage
                    )
                }
            }
        }
    }
}
