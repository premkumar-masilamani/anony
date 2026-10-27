import SwiftUI

/// Step 2 of the guided progressive disclosure stepper.
/// Allows clients to specify their struggle category and pricing tier preference.
public struct MatchPreferencesStepView: View {
    @Binding public var selectedCategory: StruggleCategory?
    @Binding public var selectedTier: PricingTier?
    public let onContinue: () -> Void

    public init(
        selectedCategory: Binding<StruggleCategory?>,
        selectedTier: Binding<PricingTier?>,
        onContinue: @escaping () -> Void
    ) {
        self._selectedCategory = selectedCategory
        self._selectedTier = selectedTier
        self.onContinue = onContinue
    }

    public var isReadyToAdvance: Bool {
        selectedCategory != nil && selectedTier != nil
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("What brings you to Anony?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("Choose your primary focus area. You can adjust this anytime.")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                // Struggle Categories Section
                VStack(spacing: 12) {
                    ForEach(StruggleCategory.allCases) { category in
                        categoryCard(category)
                    }
                }

                // Pricing Tier Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Coaching Preference")
                        .font(.headline)
                        .foregroundStyle(ColorPalette.textPrimary)
                        .padding(.top, 6)

                    VStack(spacing: 12) {
                        ForEach(PricingTier.allCases) { tier in
                            tierCard(tier)
                        }
                    }
                }

                // Continue CTA
                AnonyButton(
                    title: "Continue to Schedule",
                    systemImage: "arrow.right",
                    variant: .primary,
                    size: .large,
                    isDisabled: !isReadyToAdvance,
                    action: onContinue
                )
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
    }

    private func categoryCard(_ category: StruggleCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedCategory = category
            }
        }) {
            GlassCard(
                style: isSelected ? .highlighted(ColorPalette.calmingCyan) : .standard,
                cornerRadius: 16
            ) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? ColorPalette.calmingCyan.opacity(0.2) : ColorPalette.warmCharcoal)
                            .frame(width: 44, height: 44)

                        Image(systemName: category.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isSelected ? ColorPalette.calmingCyan : ColorPalette.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.title)
                            .font(.headline)
                            .foregroundStyle(ColorPalette.textPrimary)

                        Text(category.subtitle)
                            .font(.footnote)
                            .foregroundStyle(ColorPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? ColorPalette.calmingCyan : ColorPalette.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func tierCard(_ tier: PricingTier) -> some View {
        let isSelected = selectedTier == tier

        return Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTier = tier
            }
        }) {
            GlassCard(
                style: isSelected ? .highlighted(ColorPalette.sageGreen) : .standard,
                cornerRadius: 16
            ) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? ColorPalette.sageGreen.opacity(0.2) : ColorPalette.warmCharcoal)
                            .frame(width: 44, height: 44)

                        Image(systemName: tier.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isSelected ? ColorPalette.sageGreen : ColorPalette.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tier.title)
                            .font(.headline)
                            .foregroundStyle(ColorPalette.textPrimary)

                        Text(tier.subtitle)
                            .font(.footnote)
                            .foregroundStyle(ColorPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? ColorPalette.sageGreen : ColorPalette.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
