import SwiftUI

/// Determines which high-level screen is displayed in the Client Sanctuary flow:
/// 1. Registration (if unauthenticated)
/// 2. First-Launch 3-Step Guided Stepper (if first-time user)
/// 3. 3-Tab Main Shell (if returning user or post-stepper)
public struct ClientSanctuaryFlowView: View {
    @Binding public var isAuthenticated: Bool
    public let userAlias: String?
    public let userEmail: String?
    public let onboardingService: OnboardingServiceProtocol
    public let onSessionAuthenticated: (AuthSession) -> Void
    public let onSignOut: () -> Void

    @State private var hasCompletedOnboarding: Bool

    public init(
        isAuthenticated: Binding<Bool>,
        userAlias: String? = nil,
        userEmail: String? = nil,
        onboardingService: OnboardingServiceProtocol = UserDefaultsOnboardingService.shared,
        onSessionAuthenticated: @escaping (AuthSession) -> Void,
        onSignOut: @escaping () -> Void
    ) {
        self._isAuthenticated = isAuthenticated
        self.userAlias = userAlias
        self.userEmail = userEmail
        self.onboardingService = onboardingService
        self.onSessionAuthenticated = onSessionAuthenticated
        self.onSignOut = onSignOut
        self._hasCompletedOnboarding = State(initialValue: onboardingService.hasCompletedOnboarding())
    }

    public enum FlowState: Equatable, Sendable {
        case unauthenticated
        case firstTimeStepper
        case mainShell
    }

    public var currentFlowState: FlowState {
        if !isAuthenticated {
            return .unauthenticated
        } else if !hasCompletedOnboarding {
            return .firstTimeStepper
        } else {
            return .mainShell
        }
    }

    public var body: some View {
        Group {
            switch currentFlowState {
            case .unauthenticated:
                RegistrationView { session in
                    onSessionAuthenticated(session)
                    hasCompletedOnboarding = onboardingService.hasCompletedOnboarding()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isAuthenticated = true
                    }
                }
                .transition(.opacity)

            case .firstTimeStepper:
                ProgressiveDisclosureStepperView(onboardingService: onboardingService) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 0.96))
                ))

            case .mainShell:
                MainShellView(
                    userAlias: userAlias,
                    userEmail: userEmail,
                    onboardingService: onboardingService,
                    onSignOut: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isAuthenticated = false
                        }
                        onSignOut()
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 1.04)),
                    removal: .opacity
                ))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: currentFlowState)
    }
}
