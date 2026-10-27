import SwiftUI

/// Step 1 of the guided progressive disclosure stepper.
/// Introduces the client to coaching, sets safety expectations, and previews app navigation.
public struct MuseVoiceGuideStepView: View {
    public let onContinue: () -> Void
    @State private var isSpeaking: Bool = false

    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Interactive Voice Companion Sphere
                VStack(spacing: 14) {
                    MuseVoiceSphereView(isSpeaking: $isSpeaking, diameter: 130)
                        .padding(.top, 10)

                    Text(isSpeaking ? "Muse is guiding..." : "Tap sphere to listen to Muse")
                        .font(.caption)
                        .foregroundStyle(ColorPalette.textMuted)
                }

                // Header & Introduction
                VStack(spacing: 8) {
                    Text("Welcome to Sanctuary")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("Your private, judgment-free space for growth, perspective, and healing.")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                // 3 Core Sanctuary Pillars
                VStack(spacing: 14) {
                    pillarCard(
                        icon: "bubble.left.and.bubble.right.fill",
                        iconColor: ColorPalette.calmingCyan,
                        title: "What is Coaching?",
                        description: "A forward-looking, goal-oriented partnership focused on discovering clarity, unblocking hurdles, and personal resilience."
                    )

                    pillarCard(
                        icon: "lock.shield.fill",
                        iconColor: ColorPalette.sageGreen,
                        title: "Zero Video, 100% Anonymous",
                        description: "All conversations are encrypted and audio-only. No faces, no legal names, no pressure. You are completely safe here."
                    )

                    pillarCard(
                        icon: "square.grid.2x2.fill",
                        iconColor: ColorPalette.mutedLavender,
                        title: "Intuitive App Navigation",
                        description: "Seamlessly explore verified coaches in Discover & Match, revisit Muse for reflections, and manage bookings in My Sessions."
                    )
                }

                // Primary CTA
                AnonyButton(
                    title: "Continue to Matching",
                    systemImage: "arrow.right",
                    variant: .primary,
                    size: .large,
                    action: onContinue
                )
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
    }

    private func pillarCard(
        icon: String,
        iconColor: Color,
        title: String,
        description: String
    ) -> some View {
        GlassCard(style: .standard, cornerRadius: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(ColorPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }
}
