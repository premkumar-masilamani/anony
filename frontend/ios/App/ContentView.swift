import SwiftUI
import AnonyCore

struct ContentView: View {
    public let onboardingService: OnboardingServiceProtocol
    public let identityService: IdentityService
    public let authService: AuthServiceProtocol

    @State private var isAuthenticated: Bool
    @State private var userEmail: String?
    @State private var userAlias: String?

    public init(
        onboardingService: OnboardingServiceProtocol = UserDefaultsOnboardingService.shared,
        identityService: IdentityService = .shared,
        authService: AuthServiceProtocol = RemoteAuthService()
    ) {
        self.onboardingService = onboardingService
        self.identityService = identityService
        self.authService = authService
        self._isAuthenticated = State(initialValue: identityService.hasActiveSession())
        self._userEmail = State(initialValue: identityService.fetchEmail())
        self._userAlias = State(initialValue: identityService.fetchAlias())
    }

    var body: some View {
        ClientRootFlowView(
            isAuthenticated: $isAuthenticated,
            userAlias: userAlias,
            userEmail: userEmail,
            onboardingService: onboardingService,
            authService: authService,
            onSessionAuthenticated: { session in
                userEmail = session.email
                userAlias = session.alias
            },
            onSignOut: {
                userEmail = nil
                userAlias = nil
                Task {
                    try? await authService.logout()
                }
            }
        )
        .preferredColorScheme(.dark)
        .onAppear {
            refreshSession()
        }
    }

    private func refreshSession() {
        isAuthenticated = identityService.hasActiveSession()
        userEmail = identityService.fetchEmail()
        userAlias = identityService.fetchAlias()
    }
}

#Preview {
    ContentView()
}
