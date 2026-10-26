import SwiftUI
import AnonyCore

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            ColorPalette.midnightSlate
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header with Aura
                VStack(spacing: 12) {
                    ZStack {
                        PulsingAuraView()
                            .frame(width: 80, height: 80)

                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 36))
                            .foregroundColor(ColorPalette.calmingCyan)
                    }

                    Text("Anony")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Zero-PII Anonymous Mental Health & Coaching")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)

                // Feature Status Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            TagPillView(text: "Private & Encrypted")
                            Spacer()
                            Circle()
                                .fill(ColorPalette.sageGreen)
                                .frame(width: 8, height: 8)
                            Text("Ready")
                                .font(.caption2)
                                .foregroundColor(ColorPalette.sageGreen)
                        }

                        Text("Anonymous Client Identity")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Tokens are securely stored in iOS Keychain with zero sign-up forms required.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Actions
                AnonyButton(title: "Enter Sanctuary") {
                    // Navigate to sanctuary
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
