import SwiftUI
import AnonyCore

struct ContentView: View {
    public let onboardingService: OnboardingServiceProtocol
    public let identityService: IdentityService
    public let authService: AuthServiceProtocol

    @State private var isAuthenticated: Bool
    @State private var userEmail: String?
    @State private var userAlias: String?
    @State private var userRole: String?
    @State private var isCoachVerified: Bool = false

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
        self._userRole = State(initialValue: identityService.fetchRole())
    }

    var body: some View {
        Group {
            if isAuthenticated && userRole == "COACH" {
                if isCoachVerified {
                    CoachDashboardView(
                        coachEmail: userEmail,
                        authService: authService,
                        onSignOut: performSignOut
                    )
                } else {
                    CoachVerificationPendingView(
                        coachEmail: userEmail,
                        authService: authService,
                        onVerified: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isCoachVerified = true
                            }
                        },
                        onSignOut: performSignOut
                    )
                }
            } else {
                ClientRootFlowView(
                    isAuthenticated: $isAuthenticated,
                    userAlias: userAlias,
                    userEmail: userEmail,
                    onboardingService: onboardingService,
                    authService: authService,
                    onSessionAuthenticated: { session in
                        userEmail = session.email
                        userAlias = session.alias
                        userRole = session.role
                        isAuthenticated = true
                        if session.role == "COACH" {
                            checkCoachVerification()
                        }
                    },
                    onSignOut: performSignOut
                )
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            refreshSession()
        }
    }

    private func performSignOut() {
        userEmail = nil
        userAlias = nil
        userRole = nil
        isCoachVerified = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isAuthenticated = false
        }
        Task {
            try? await authService.logout()
        }
    }

    private func refreshSession() {
        isAuthenticated = identityService.hasActiveSession()
        userEmail = identityService.fetchEmail()
        userAlias = identityService.fetchAlias()
        userRole = identityService.fetchRole()
        if userRole == "COACH" {
            checkCoachVerification()
        }
    }

    private func checkCoachVerification() {
        Task { @MainActor in
            if let profile = try? await authService.fetchCoachProfile() {
                self.isCoachVerified = profile.isVerified
            }
        }
    }
}

#Preview {
    ContentView()
}
