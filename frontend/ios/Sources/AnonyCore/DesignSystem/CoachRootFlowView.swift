import SwiftUI

/// Determines which high-level screen is displayed in the Coach application flow (Issue #18):
/// 1. Coach Verification Pending View (when `isCoachVerified == false`)
/// 2. 3-Screen Coach Dashboard (when `isCoachVerified == true`)
public struct CoachRootFlowView: View {
    @Binding public var isCoachVerified: Bool
    public let coachEmail: String?
    public let authService: AuthServiceProtocol
    public let onSignOut: () -> Void

    public init(
        isCoachVerified: Binding<Bool>,
        coachEmail: String? = nil,
        authService: AuthServiceProtocol = RemoteAuthService(),
        onSignOut: @escaping () -> Void
    ) {
        self._isCoachVerified = isCoachVerified
        self.coachEmail = coachEmail
        self.authService = authService
        self.onSignOut = onSignOut
    }

    public enum FlowState: Equatable, Sendable {
        case verificationPending
        case verifiedDashboard
    }

    public var currentFlowState: FlowState {
        isCoachVerified ? .verifiedDashboard : .verificationPending
    }

    public var body: some View {
        Group {
            switch currentFlowState {
            case .verificationPending:
                CoachVerificationPendingView(
                    coachEmail: coachEmail,
                    authService: authService,
                    onVerified: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            isCoachVerified = true
                        }
                    },
                    onSignOut: onSignOut
                )
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 0.96))
                ))

            case .verifiedDashboard:
                CoachDashboardView(
                    coachEmail: coachEmail,
                    authService: authService,
                    onSignOut: onSignOut
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
