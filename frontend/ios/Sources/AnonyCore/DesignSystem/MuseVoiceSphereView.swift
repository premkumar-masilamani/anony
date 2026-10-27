import SwiftUI

/// An interactive, zero-anxiety voice sphere companion representing Muse.
/// Uses concentric tranquil breathing rings with calming 3.5s pacing.
public struct MuseVoiceSphereView: View {
    @Binding public var isSpeaking: Bool
    public let diameter: CGFloat
    public let cycleDuration: Double

    public init(
        isSpeaking: Binding<Bool>,
        diameter: CGFloat = 140,
        cycleDuration: Double = 3.5
    ) {
        self._isSpeaking = isSpeaking
        self.diameter = diameter
        self.cycleDuration = cycleDuration
    }

    public var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                isSpeaking.toggle()
            }
        }) {
            ZStack {
                // Ambient calming breathing aura
                PulsingAuraView(
                    color: isSpeaking ? ColorPalette.sageGreen : ColorPalette.calmingCyan,
                    diameter: diameter,
                    cycleDuration: isSpeaking ? 2.5 : cycleDuration,
                    scaleRange: isSpeaking ? 0.95...1.25 : 0.92...1.15
                )

                // Secondary soft glow layer
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (isSpeaking ? ColorPalette.sageGreen : ColorPalette.calmingCyan).opacity(0.35),
                                ColorPalette.midnightSlate.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: diameter * 0.55
                        )
                    )
                    .frame(width: diameter, height: diameter)

                // Core tranquil sphere
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ColorPalette.elevatedCard,
                                ColorPalette.warmCharcoal
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        (isSpeaking ? ColorPalette.sageGreen : ColorPalette.calmingCyan).opacity(0.8),
                                        ColorPalette.cardBorder
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                    )
                    .frame(width: diameter * 0.7, height: diameter * 0.7)
                    .shadow(
                        color: (isSpeaking ? ColorPalette.sageGreen : ColorPalette.calmingCyan).opacity(0.35),
                        radius: 16,
                        x: 0,
                        y: 0
                    )

                // Center symbolic indicator
                Image(systemName: isSpeaking ? "waveform" : "sparkles")
                    .font(.system(size: diameter * 0.22, weight: .medium))
                    .foregroundStyle(isSpeaking ? ColorPalette.sageGreen : ColorPalette.calmingCyan)
                    .symbolEffect(.bounce, value: isSpeaking)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSpeaking ? "Muse Voice Guide is speaking. Tap to pause." : "Muse Voice Guide is idle. Tap to activate.")
    }
}
