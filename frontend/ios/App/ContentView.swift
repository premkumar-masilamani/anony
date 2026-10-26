import SwiftUI
import AnonyCore

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var isAuthenticated: Bool = IdentityService.shared.hasActiveSession()

    var body: some View {
        Group {
            if isAuthenticated {
                authenticatedMainView
            } else {
                RegistrationView { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isAuthenticated = true
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isAuthenticated = IdentityService.shared.hasActiveSession()
        }
    }

    private var authenticatedMainView: some View {
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
                #if os(iOS)
                TabView(selection: $selectedTab) {
                    VisualTemplates.SanctuaryView(
                        onLogout: {
                            _ = IdentityService.shared.clearSession()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isAuthenticated = false
                            }
                        }
                    )
                    .tag(0)

                    VisualTemplates.DesignSystemGalleryView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                #else
                Group {
                    if selectedTab == 0 {
                        VisualTemplates.SanctuaryView(
                            onLogout: {
                                _ = IdentityService.shared.clearSession()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isAuthenticated = false
                                }
                            }
                        )
                    } else {
                        VisualTemplates.DesignSystemGalleryView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                #endif
            }
        }
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
