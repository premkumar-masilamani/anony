import Foundation
import SwiftUI

/// ViewModel managing the Coach Verification Status screen (Issue #18).
/// Handles initial load, pull-to-refresh, and periodic polling against `GET /api/v1/coaches/me`,
/// immediately unlocking the Coach Dashboard once `isVerified == true`.
@MainActor
public final class CoachVerificationViewModel: ObservableObject {
    @Published public var profile: CoachProfileResponse?
    @Published public private(set) var isVerified: Bool = false
    @Published public private(set) var isRefreshing: Bool = false
    @Published public var statusMessage: String?

    public let authService: AuthServiceProtocol
    private let onVerified: () -> Void
    private var hasNotifiedVerified: Bool = false

    public var statusLabel: String {
        isVerified ? "Verified" : "Under Review"
    }

    public init(
        authService: AuthServiceProtocol = RemoteAuthService(),
        onVerified: @escaping () -> Void = {}
    ) {
        self.authService = authService
        self.onVerified = onVerified
    }

    /// Queries `GET /api/v1/coaches/me` once (used by pull-to-refresh and polling ticks).
    public func checkVerificationStatus() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let fetched = try await authService.fetchCoachProfile()
            self.profile = fetched
            self.isVerified = fetched.isVerified
            if fetched.isVerified && !hasNotifiedVerified {
                hasNotifiedVerified = true
                onVerified()
            }
        } catch {
            // Preserve existing profile and Under Review state on transient network failure
        }
    }

    /// Starts periodic polling of `GET /api/v1/coaches/me` until `isVerified == true` or the task is cancelled.
    public func startPolling(intervalNanoseconds: UInt64 = 10_000_000_000) async {
        await checkVerificationStatus()

        while !isVerified && !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: intervalNanoseconds)
            } catch {
                break
            }
            guard !Task.isCancelled && !isVerified else { break }
            await checkVerificationStatus()
        }
    }

    /// Applies an updated profile after editing credentials from the verification screen.
    public func applyUpdatedProfile(_ updated: CoachProfileResponse) {
        self.profile = updated
        self.isVerified = updated.isVerified
        self.statusMessage = "Profile updated and resubmitted for review."
        if updated.isVerified && !hasNotifiedVerified {
            hasNotifiedVerified = true
            onVerified()
        }
    }
}
