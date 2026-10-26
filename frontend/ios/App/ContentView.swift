import SwiftUI
import AnonyCore

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            ColorPalette.midnightSlate
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top tranquil navigation selector
                HStack(spacing: 12) {
                    navTabButton(title: "Sanctuary", systemImage: "sparkles", index: 0)
                    navTabButton(title: "Design System", systemImage: "paintpalette.fill", index: 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(ColorPalette.midnightSlate)

                // Tab content
                TabView(selection: $selectedTab) {
                    VisualTemplates.SanctuaryView()
                        .tag(0)

                    VisualTemplates.DesignSystemGalleryView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .preferredColorScheme(.dark)
    }

    private func navTabButton(title: String, systemImage: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = index
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(selectedTab == index ? .bold : .medium)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .foregroundColor(selectedTab == index ? ColorPalette.midnightSlate : ColorPalette.textSecondary)
            .background(selectedTab == index ? ColorPalette.calmingCyan : ColorPalette.elevatedCard)
            .cornerRadius(10)
        }
    }
}

#Preview {
    ContentView()
}
