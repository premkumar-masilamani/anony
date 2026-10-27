import SwiftUI

/// Root coordinator for the first-launch 3-step progressive disclosure flow:
/// Step 1: Learn with Muse Voice Guide
/// Step 2: Match Preferences (Struggle category & Free vs Paid)
/// Step 3: Schedule Session (Local timezone & Date/Time slot)
public struct ProgressiveDisclosureStepperView: View {
    public let onboardingService: OnboardingServiceProtocol
    public let onComplete: () -> Void

    @State private var currentStep: Int = 1
    @State private var selectedCategory: StruggleCategory? = nil
    @State private var selectedTier: PricingTier? = nil

    public init(
        onboardingService: OnboardingServiceProtocol = UserDefaultsOnboardingService.shared,
        onComplete: @escaping () -> Void
    ) {
        self.onboardingService = onboardingService
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            // Sanctuary background
            ColorPalette.sanctuaryGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Stepper Top Bar & Progress
                stepperHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                // Current Step Content with Gentle Spring Transition
                Group {
                    switch currentStep {
                    case 1:
                        MuseVoiceGuideStepView(onContinue: {
                            advanceToStep(2)
                        })
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))

                    case 2:
                        MatchPreferencesStepView(
                            selectedCategory: $selectedCategory,
                            selectedTier: $selectedTier,
                            onContinue: {
                                advanceToStep(3)
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))

                    case 3:
                        if let category = selectedCategory, let tier = selectedTier {
                            ScheduleSessionStepView(
                                selectedCategory: category,
                                selectedTier: tier,
                                onConfirm: { preferences in
                                    completeOnboarding(with: preferences)
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                        } else {
                            // Fallback safety if navigated prematurely
                            EmptyView()
                        }

                    default:
                        EmptyView()
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: currentStep)
            }
        }
    }

    private var stepperHeader: some View {
        VStack(spacing: 12) {
            HStack {
                if currentStep > 1 {
                    Button(action: {
                        regressToStep(currentStep - 1)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.subheadline)
                        }
                        .foregroundStyle(ColorPalette.calmingCyan)
                    }
                } else {
                    TagPillView(text: "First-Time Guide", variant: .cyan)
                }

                Spacer()

                Text("Step \(currentStep) of 3")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorPalette.textMuted)
            }

            // Continuous Progress Bar
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ColorPalette.cardBorder)
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [ColorPalette.calmingCyan, ColorPalette.sageGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * (CGFloat(currentStep) / 3.0), height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                }
            }
            .frame(height: 4)
        }
    }

    private func advanceToStep(_ step: Int) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentStep = step
        }
    }

    private func regressToStep(_ step: Int) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentStep = step
        }
    }

    private func completeOnboarding(with preferences: OnboardingPreferences) {
        onboardingService.savePreferences(preferences)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            onComplete()
        }
    }
}
