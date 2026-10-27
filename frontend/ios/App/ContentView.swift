import SwiftUI
import AnonyCore

struct ContentView: View {
    @State private var isAuthenticated: Bool = IdentityService.shared.hasActiveSession()
    @State private var userEmail: String? = IdentityService.shared.fetchEmail()
    @State private var userAlias: String? = IdentityService.shared.fetchAlias()

    var body: some View {
        Group {
            if isAuthenticated {
                authenticatedView
            } else {
                RegistrationView { session in
                    userEmail = session.email
                    userAlias = session.alias
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isAuthenticated = true
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            refreshSession()
        }
    }

    private var authenticatedView: some View {
        ZStack {
            ColorPalette.midnightSlate
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                GlassCard(style: .elevated, cornerRadius: 20) {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 54))
                            .foregroundColor(ColorPalette.sageGreen)

                        Text("You are logged in")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.textPrimary)

                        if let email = userEmail, !email.isEmpty {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(ColorPalette.textSecondary)
                        } else if let alias = userAlias, !alias.isEmpty {
                            Text(alias)
                                .font(.subheadline)
                                .foregroundColor(ColorPalette.calmingCyan)
                        }

                        AnonyButton(
                            title: "Log Out",
                            systemImage: "rectangle.portrait.and.arrow.right",
                            variant: .secondary,
                            size: .medium
                        ) {
                            _ = IdentityService.shared.clearSession()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isAuthenticated = false
                                userEmail = nil
                                userAlias = nil
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(28)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    private func refreshSession() {
        isAuthenticated = IdentityService.shared.hasActiveSession()
        userEmail = IdentityService.shared.fetchEmail()
        userAlias = IdentityService.shared.fetchAlias()
    }
}

#Preview {
    ContentView()
}
