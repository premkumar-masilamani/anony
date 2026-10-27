import SwiftUI

/// Step 3 of the guided progressive disclosure stepper.
/// Allows clients to schedule their initial anonymous coaching session in their local timezone.
public struct ScheduleSessionStepView: View {
    public let selectedCategory: StruggleCategory
    public let selectedTier: PricingTier
    public let onConfirm: (OnboardingPreferences) -> Void

    @State private var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var selectedTimeSlot: String = "10:00 AM"

    public let availableTimeSlots: [String] = [
        "10:00 AM",
        "2:30 PM",
        "6:00 PM"
    ]

    public var localTimeZoneName: String {
        TimeZone.current.localizedName(for: .generic, locale: .current) ?? TimeZone.current.identifier
    }

    public init(
        selectedCategory: StruggleCategory,
        selectedTier: PricingTier,
        onConfirm: @escaping (OnboardingPreferences) -> Void
    ) {
        self.selectedCategory = selectedCategory
        self.selectedTier = selectedTier
        self.onConfirm = onConfirm
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Schedule Your First Session")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("Pick a quiet time for your audio sanctuary. No video, zero pressure.")
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
                                .font(.caption)
                                .foregroundStyle(ColorPalette.textMuted)

                            Text(localTimeZoneName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(ColorPalette.textPrimary)
                        }

                        Spacer()

                        TagPillView(text: "Live", systemImage: "antenna.radiowaves.left.and.right", variant: .cyan)
                    }
                }

                // Date Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Date")
                        .font(.headline)
                        .foregroundStyle(ColorPalette.textPrimary)

                    DatePicker(
                        "Session Date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(ColorPalette.calmingCyan)
                    .colorScheme(.dark)
                    .padding(12)
                    .background(ColorPalette.elevatedCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ColorPalette.cardBorder, lineWidth: 1)
                    )
                }

                // Time Slot Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Time Slot")
                        .font(.headline)
                        .foregroundStyle(ColorPalette.textPrimary)

                    HStack(spacing: 12) {
                        ForEach(availableTimeSlots, id: \.self) { slot in
                            slotButton(slot)
                        }
                    }
                }

                // Booking Summary Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Session Summary")
                        .font(.headline)
                        .foregroundStyle(ColorPalette.textPrimary)

                    GlassCard(style: .elevated, cornerRadius: 16) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                TagPillView(
                                    text: selectedCategory.title,
                                    systemImage: selectedCategory.systemImage,
                                    variant: .cyan
                                )

                                Spacer()

                                TagPillView(
                                    text: selectedTier.title,
                                    systemImage: selectedTier.systemImage,
                                    variant: .sage
                                )
                            }

                            Divider()
                                .background(ColorPalette.cardBorder)

                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Date & Time")
                                        .font(.caption)
                                        .foregroundStyle(ColorPalette.textMuted)

                                    Text("\(formattedDate(selectedDate)) at \(selectedTimeSlot)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(ColorPalette.textPrimary)
                                }

                                Spacer()

                                TagPillView(
                                    text: "100% Anonymous",
                                    systemImage: "lock.shield.fill",
                                    variant: .neutral
                                )
                            }
                        }
                    }
                }

                // Confirm CTA
                AnonyButton(
                    title: "Confirm & Enter Sanctuary",
                    systemImage: "checkmark.circle.fill",
                    variant: .primary,
                    size: .large,
                    action: {
                        let preferences = OnboardingPreferences(
                            struggleCategory: selectedCategory,
                            pricingTier: selectedTier,
                            scheduledDate: selectedDate,
                            timeSlot: selectedTimeSlot,
                            timeZoneIdentifier: TimeZone.current.identifier
                        )
                        onConfirm(preferences)
                    }
                )
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
    }

    private func slotButton(_ slot: String) -> some View {
        let isSelected = selectedTimeSlot == slot

        return Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTimeSlot = slot
            }
        }) {
            Text(slot)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? ColorPalette.calmingCyan.opacity(0.18) : ColorPalette.elevatedCard)
                .foregroundStyle(isSelected ? ColorPalette.calmingCyan : ColorPalette.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? ColorPalette.calmingCyan : ColorPalette.cardBorder, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
