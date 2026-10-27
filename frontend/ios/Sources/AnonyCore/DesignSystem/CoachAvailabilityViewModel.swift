import Foundation
import Combine

/// View model managing coach availability slot creation, 24-hour advance scheduling enforcement,
/// and the mandatory 1-hour (60-minute) monthly free session pledge quota.
@MainActor
public final class CoachAvailabilityViewModel: ObservableObject {
    nonisolated public static let mandatoryMonthlyFreeMinutes: Int = 60
    nonisolated public static let minimumAdvanceSeconds: TimeInterval = 24 * 3600
    nonisolated public static let supportedDurations: [Int] = [30, 60]

    @Published public var selectedStartTime: Date
    @Published public var selectedDurationMinutes: Int = 60
    @Published public var offerAsFreeAnonymousSession: Bool = true
    @Published public private(set) var draftedSlots: [CoachAvailabilitySlotPayload] = []
    @Published public private(set) var publishedSlots: [CoachAvailabilitySlotResponse] = []
    @Published public private(set) var isSubmitting: Bool = false
    @Published public private(set) var isLoadingPublished: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var statusMessage: String? = nil

    private let authService: AuthServiceProtocol

    public init(
        authService: AuthServiceProtocol = RemoteAuthService(),
        initialStartTime: Date? = nil
    ) {
        self.authService = authService
        self.selectedStartTime = initialStartTime ?? Self.defaultInitialSlotStart(from: Date())
    }

    /// Computes a default initial slot start timestamp 25 hours in the future rounded to the next 30-minute mark.
    public static func defaultInitialSlotStart(from referenceDate: Date = Date()) -> Date {
        let base = referenceDate.addingTimeInterval(25 * 3600)
        let interval: TimeInterval = 30 * 60
        let roundedTimestamp = ceil(base.timeIntervalSince1970 / interval) * interval
        return Date(timeIntervalSince1970: roundedTimestamp)
    }

    /// Returns the earliest valid start timestamp (24 hours in advance of the reference date).
    public func minimumAdvanceDate(from referenceDate: Date = Date()) -> Date {
        referenceDate.addingTimeInterval(Self.minimumAdvanceSeconds)
    }

    /// Checks whether a candidate start time satisfies the 24-hour advance scheduling rule.
    public func isAtLeast24HoursInAdvance(_ candidateStart: Date, from referenceDate: Date = Date()) -> Bool {
        candidateStart.timeIntervalSince(referenceDate) >= Self.minimumAdvanceSeconds
    }

    /// Total free anonymous session minutes pledged across published and drafted slots.
    public var pledgedFreeMinutes: Int {
        let draftedMinutes = draftedSlots
            .filter(\.isFreePledge)
            .reduce(0) { $0 + $1.durationMinutes }
        let publishedMinutes = publishedSlots
            .filter(\.isFreePledge)
            .reduce(0) { $0 + $1.durationMinutes }
        return draftedMinutes + publishedMinutes
    }

    /// Remaining minutes needed to satisfy the 60-minute monthly free session pledge.
    public var remainingFreeMinutes: Int {
        max(0, Self.mandatoryMonthlyFreeMinutes - pledgedFreeMinutes)
    }

    /// Normalized progress value (`0.0 ... 1.0`) for the visual free pledge progress ring.
    public var pledgeProgress: Double {
        let raw = Double(pledgedFreeMinutes) / Double(Self.mandatoryMonthlyFreeMinutes)
        return min(1.0, max(0.0, raw))
    }

    /// Indicates whether the mandatory 1-hour (60-minute) monthly free session pledge is satisfied.
    public var isPledgeSatisfied: Bool {
        pledgedFreeMinutes >= Self.mandatoryMonthlyFreeMinutes
    }

    /// Human-readable summary of the monthly free pledge status.
    public var pledgeStatusSummary: String {
        if isPledgeSatisfied {
            return "\(pledgedFreeMinutes) / \(Self.mandatoryMonthlyFreeMinutes) mins pledged — Monthly requirement met"
        } else {
            return "\(pledgedFreeMinutes) / \(Self.mandatoryMonthlyFreeMinutes) mins pledged (\(remainingFreeMinutes) mins remaining)"
        }
    }

    /// Indicates whether the coach can submit the current batch of drafted slots.
    public var canSubmitAvailabilities: Bool {
        !draftedSlots.isEmpty && isPledgeSatisfied && !isSubmitting
    }

    /// Validates and adds the currently configured slot to `draftedSlots`.
    @discardableResult
    public func addDraftSlot(referenceDate: Date = Date()) -> Bool {
        errorMessage = nil
        statusMessage = nil

        guard Self.supportedDurations.contains(selectedDurationMinutes) else {
            errorMessage = "Slot duration must be either 30 or 60 minutes."
            return false
        }

        guard isAtLeast24HoursInAdvance(selectedStartTime, from: referenceDate) else {
            errorMessage = "Slots must be scheduled at least 24 hours in advance."
            return false
        }

        let candidateEndTime = selectedStartTime.addingTimeInterval(TimeInterval(selectedDurationMinutes * 60))

        for existingDraft in draftedSlots {
            if selectedStartTime < existingDraft.endAt && existingDraft.startAt < candidateEndTime {
                errorMessage = "This time window overlaps with another drafted slot."
                return false
            }
        }

        for existingPublished in publishedSlots {
            if selectedStartTime < existingPublished.endAt && existingPublished.startAt < candidateEndTime {
                errorMessage = "This time window overlaps with an already published slot."
                return false
            }
        }

        let newSlot = CoachAvailabilitySlotPayload(
            startAt: selectedStartTime,
            endAt: candidateEndTime,
            durationMinutes: selectedDurationMinutes,
            isFreePledge: offerAsFreeAnonymousSession
        )
        draftedSlots.append(newSlot)
        draftedSlots.sort { $0.startAt < $1.startAt }

        // Advance picker to the end of the newly added slot for convenient sequential scheduling
        selectedStartTime = candidateEndTime
        return true
    }

    /// Removes a drafted slot by its identifier.
    public func removeDraftSlot(id: UUID) {
        draftedSlots.removeAll { $0.id == id }
        errorMessage = nil
    }

    /// Loads existing unbooked availability slots for the coach from the backend.
    public func loadPublishedAvailabilities(coachId: UUID, from: Date? = nil, to: Date? = nil) async {
        isLoadingPublished = true
        errorMessage = nil
        do {
            let fetched = try await authService.fetchCoachAvailabilities(coachId: coachId, from: from, to: to)
            publishedSlots = fetched.sorted { $0.startAt < $1.startAt }
            isLoadingPublished = false
        } catch {
            errorMessage = error.localizedDescription
            isLoadingPublished = false
        }
    }

    /// Submits the drafted availability slots to `POST /api/v1/coaches/me/availabilities` after validating
    /// the 24-hour advance window and the 1-hour monthly free session pledge requirement.
    @discardableResult
    public func submitAvailabilities(referenceDate: Date = Date()) async -> Bool {
        errorMessage = nil
        statusMessage = nil

        guard !draftedSlots.isEmpty else {
            errorMessage = "Add at least one availability slot before publishing."
            return false
        }

        for slot in draftedSlots {
            if !isAtLeast24HoursInAdvance(slot.startAt, from: referenceDate) {
                errorMessage = "All slots must be scheduled at least 24 hours in advance."
                return false
            }
        }

        guard isPledgeSatisfied else {
            errorMessage = "Please allocate at least 60 minutes (one 60-min or two 30-min slots) as a Free Anonymous Session pledge for the month."
            return false
        }

        isSubmitting = true
        do {
            let createdSlots = try await authService.publishCoachAvailabilities(slots: draftedSlots)
            publishedSlots.append(contentsOf: createdSlots)
            publishedSlots.sort { $0.startAt < $1.startAt }
            draftedSlots.removeAll()
            isSubmitting = false
            statusMessage = "Availability calendar published with your monthly free session pledge."
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return false
        }
    }
}
