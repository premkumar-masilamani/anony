import SwiftUI

/// Step 1 of the guided progressive disclosure stepper.
/// Voice-guided educational primer explaining what coaching is, what coaching is not,
/// and setting clear boundaries that all sessions are 1-on-1 with verified human coaches.
public struct MuseVoiceGuideStepView: View {
    public let onContinue: () -> Void
    @State private var isSpeaking: Bool = false

    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Interactive Educational Voice Sphere
                VStack(spacing: 12) {
                    MuseVoiceSphereView(isSpeaking: $isSpeaking, diameter: 120)
                        .padding(.top, 8)

                    Text(isSpeaking ? "Playing: What Coaching Is & Is Not (1m 20s)" : "Tap sphere to listen to Muse Guide")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(isSpeaking ? ColorPalette.sageGreen : ColorPalette.textMuted)

                    Text("Educational audio walkthrough • Zero AI in coaching calls")
                        .font(.caption2)
                        .foregroundStyle(ColorPalette.textMuted)
                }

                // Header & Introduction
                VStack(spacing: 8) {
                    Text("Understanding Coaching")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("Anony connects you with verified human coaches for confidential 1-on-1 audio calls. Zero video, zero PII.")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                // Educational Sections: What Coaching IS vs. What It IS NOT
                VStack(spacing: 14) {
                    // What Coaching IS
                    GlassCard(style: .highlighted(ColorPalette.sageGreen), cornerRadius: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(ColorPalette.sageGreen)
                                    .font(.headline)

                                Text("WHAT COACHING IS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(ColorPalette.sageGreen)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                bulletPoint(
                                    bold: "Forward-Looking Partnership: ",
                                    detail: "Focused on clarity, personal resilience, and unlocking future potential."
                                )
                                bulletPoint(
                                    bold: "1-on-1 Real Human Voice: ",
                                    detail: "Confidential, encrypted audio sessions with experienced human coaches."
                                )
                                bulletPoint(
                                    bold: "Empowerment & Action: ",
                                    detail: "Unblocking hurdles, accountability, and practical goal-setting."
                                )
                            }
                        }
                    }

                    // What Coaching IS NOT
                    GlassCard(style: .highlighted(ColorPalette.mutedLavender), cornerRadius: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(ColorPalette.mutedLavender)
                                    .font(.headline)

                                Text("WHAT COACHING IS NOT")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(ColorPalette.mutedLavender)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                bulletPoint(
                                    bold: "Not Therapy or Psychiatry: ",
                                    detail: "We do not treat clinical psychological illness, trauma, or prescribe medications."
                                )
                                bulletPoint(
                                    bold: "Not AI Chat Conversations: ",
                                    detail: "You never speak with bots during your coaching sessions. All calls are human-to-human."
                                )
                                bulletPoint(
                                    bold: "Not Passive Listening: ",
                                    detail: "It is an active, collaborative dialog toward tangible personal growth."
                                )
                            }
                        }
                    }
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

    private func bulletPoint(bold: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundStyle(ColorPalette.textMuted)
                .font(.footnote)
            (
                Text(bold)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.textPrimary)
                + Text(detail)
                    .foregroundColor(ColorPalette.textSecondary)
            )
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
