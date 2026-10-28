import Foundation
import Testing
import SwiftUI
@testable import AnonyCore

private final class AvailabilityMockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = AvailabilityMockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class MockCoachAvailabilityAuthService: AuthServiceProtocol, @unchecked Sendable {
    var publishedResponsesToReturn: [CoachAvailabilitySlotResponse] = []
    var fetchedResponsesToReturn: [CoachAvailabilitySlotResponse] = []
    var shouldThrowError: Bool = false
    var lastSubmittedSlots: [CoachAvailabilitySlotPayload] = []

    func register(email: String, password: String) async throws -> AuthSession {
        AuthSession(token: "t", alias: "a", avatarId: "av", email: email, role: "COACH")
    }

    func registerCoach(payload: CoachRegistrationPayload) async throws -> AuthSession {
        AuthSession(token: "t", alias: "a", avatarId: "av", email: payload.email, role: "COACH")
    }

    func login(email: String, password: String) async throws -> AuthSession {
        AuthSession(token: "t", alias: "a", avatarId: "av", email: email, role: "COACH")
    }

    func logout() async throws {}

    func fetchCoachProfile() async throws -> CoachProfileResponse {
        CoachProfileResponse(
            coachId: UUID(),
            userId: UUID(),
            email: "coach@anony.app",
            firstName: "Maya",
            lastName: "Raman",
            timezone: "UTC",
            biography: "Bio",
            icfLevel: "PCC",
            icfAcc: false,
            icfPcc: true,
            icfMcc: false,
            icfActc: false,
            credentialDetails: "ICF-PCC",
            isVerified: true,
            isOnboarded: true,
            domainCodes: ["CAREER"],
            createdAt: Date()
        )
    }

    func updateCoachProfile(payload: CoachUpdatePayload) async throws -> CoachProfileResponse {
        try await fetchCoachProfile()
    }

    func fetchClientProfile() async throws -> ClientProfileResponse {
        ClientProfileResponse(
            clientId: UUID(),
            userId: UUID(),
            email: "client@anony.app",
            firstName: "Calm",
            lastName: "River",
            alias: "CalmRiver10",
            isAnonymous: true,
            isOnboarded: true,
            createdAt: Date()
        )
    }

    func publishCoachAvailabilities(slots: [CoachAvailabilitySlotPayload]) async throws -> [CoachAvailabilitySlotResponse] {
        if shouldThrowError {
            throw AuthError.registrationFailed("Server rejected slots.")
        }
        lastSubmittedSlots = slots
        if !publishedResponsesToReturn.isEmpty {
            return publishedResponsesToReturn
        }
        let coachId = UUID()
        return slots.map { slot in
            CoachAvailabilitySlotResponse(
                slotId: slot.id,
                coachId: coachId,
                startAt: slot.startAt,
                endAt: slot.endAt,
                durationMinutes: slot.durationMinutes,
                isFreePledge: slot.isFreePledge,
                isBooked: false
            )
        }
    }

    func fetchCoachAvailabilities(coachId: UUID, from: Date?, to: Date?) async throws -> [CoachAvailabilitySlotResponse] {
        if shouldThrowError {
            throw AuthError.registrationFailed("Unable to load slots.")
        }
        return fetchedResponsesToReturn
    }
}

@Suite("CoachAvailabilityTests", .serialized)
struct CoachAvailabilityTests {

    @Test("CoachAvailabilitySlotPayload and CoachAvailabilitySlotResponse encode and decode UTC timestamps and is_free_pledge")
    func testCoachAvailabilityModelsCodable() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let payload = CoachAvailabilitySlotPayload(
            startAt: start,
            durationMinutes: 60,
            isFreePledge: true
        )

        #expect(payload.endAt == start.addingTimeInterval(3600))
        #expect(!payload.formattedDate(in: TimeZone(secondsFromGMT: 0)!).isEmpty)
        #expect(!payload.formattedTimeRange(in: TimeZone(secondsFromGMT: 0)!).isEmpty)

        let batch = CoachAvailabilityPublishPayload(slots: [payload])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(batch)
        let jsonString = String(data: encodedData, encoding: .utf8) ?? ""
        #expect(jsonString.contains("is_free_pledge"))

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedBatch = try decoder.decode(CoachAvailabilityPublishPayload.self, from: encodedData)
        #expect(decodedBatch.slots.count == 1)
        #expect(decodedBatch.slots[0].durationMinutes == 60)
        #expect(decodedBatch.slots[0].isFreePledge == true)

        // Snake-case only JSON decoding for CoachAvailabilitySlotResponse
        let snakeCaseResponseJSON = """
        {
          "slotId": "11111111-2222-3333-4444-555555555555",
          "coachId": "22222222-3333-4444-5555-666666666666",
          "startAt": "2027-05-10T14:00:00Z",
          "endAt": "2027-05-10T14:30:00Z",
          "durationMinutes": 30,
          "is_free_pledge": true,
          "isBooked": false
        }
        """.data(using: .utf8)!

        let decodedResponse = try decoder.decode(CoachAvailabilitySlotResponse.self, from: snakeCaseResponseJSON)
        #expect(decodedResponse.durationMinutes == 30)
        #expect(decodedResponse.isFreePledge == true)
        #expect(decodedResponse.isBooked == false)
    }

    @Test("CoachAvailabilityViewModel enforces 24-hour advance scheduling window and tracks 1-hour monthly free pledge progress")
    @MainActor
    func testViewModelAdvanceWindowAndFreePledgeQuota() async {
        let mockService = MockCoachAvailabilityAuthService()
        let referenceNow = Date(timeIntervalSince1970: 1_800_000_000)
        let tooSoonDate = referenceNow.addingTimeInterval(12 * 3600) // Only 12h ahead
        let validStartDate = referenceNow.addingTimeInterval(30 * 3600) // 30h ahead

        let viewModel = CoachAvailabilityViewModel(
            authService: mockService,
            initialStartTime: tooSoonDate
        )

        #expect(viewModel.pledgedFreeMinutes == 0)
        #expect(viewModel.pledgeProgress == 0.0)
        #expect(viewModel.isPledgeSatisfied == false)
        #expect(viewModel.canSubmitAvailabilities == false)

        // 1. Attempt to add slot < 24h in advance -> rejected
        let addedTooSoon = viewModel.addDraftSlot(referenceDate: referenceNow)
        #expect(addedTooSoon == false)
        #expect(viewModel.draftedSlots.isEmpty)
        #expect(viewModel.errorMessage == "Slots must be scheduled at least 24 hours in advance.")

        // 2. Add a 30-min Free Anonymous Session slot (>= 24h ahead) -> progress is 0.5 (30 / 60 mins)
        viewModel.selectedStartTime = validStartDate
        viewModel.selectedDurationMinutes = 30
        viewModel.offerAsFreeAnonymousSession = true
        let addedFirstHalf = viewModel.addDraftSlot(referenceDate: referenceNow)
        #expect(addedFirstHalf == true)
        #expect(viewModel.draftedSlots.count == 1)
        #expect(viewModel.pledgedFreeMinutes == 30)
        #expect(viewModel.remainingFreeMinutes == 30)
        #expect(viewModel.pledgeProgress == 0.5)
        #expect(viewModel.isPledgeSatisfied == false)
        #expect(viewModel.canSubmitAvailabilities == false)

        // 3. Attempting to submit with only 30 mins of free pledge fails validation
        let prematureSubmit = await viewModel.submitAvailabilities(referenceDate: referenceNow)
        #expect(prematureSubmit == false)
        #expect(viewModel.errorMessage != nil)

        // 4. Add second 30-min Free Anonymous Session slot -> progress reaches 1.0 (60 / 60 mins)
        let addedSecondHalf = viewModel.addDraftSlot(referenceDate: referenceNow)
        #expect(addedSecondHalf == true)
        #expect(viewModel.draftedSlots.count == 2)
        #expect(viewModel.pledgedFreeMinutes == 60)
        #expect(viewModel.remainingFreeMinutes == 0)
        #expect(viewModel.pledgeProgress == 1.0)
        #expect(viewModel.isPledgeSatisfied == true)
        #expect(viewModel.canSubmitAvailabilities == true)

        // 5. Add a standard paid 60-min slot (offerAsFreeAnonymousSession = false)
        viewModel.selectedDurationMinutes = 60
        viewModel.offerAsFreeAnonymousSession = false
        let addedPaidSlot = viewModel.addDraftSlot(referenceDate: referenceNow)
        #expect(addedPaidSlot == true)
        #expect(viewModel.draftedSlots.count == 3)
        #expect(viewModel.pledgedFreeMinutes == 60)

        // 6. Submit availabilities to backend -> succeeds and moves slots to publishedSlots
        let submitted = await viewModel.submitAvailabilities(referenceDate: referenceNow)
        #expect(submitted == true)
        #expect(mockService.lastSubmittedSlots.count == 3)
        #expect(viewModel.draftedSlots.isEmpty)
        #expect(viewModel.publishedSlots.count == 3)
        #expect(viewModel.pledgedFreeMinutes == 60)
        #expect(viewModel.isPledgeSatisfied == true)
        #expect(viewModel.statusMessage != nil)
    }

    @Test("CoachAvailabilityViewModel prevents overlapping slots and supports slot removal")
    @MainActor
    func testViewModelOverlapAndRemoval() {
        let mockService = MockCoachAvailabilityAuthService()
        let referenceNow = Date(timeIntervalSince1970: 1_800_000_000)
        let validStartDate = referenceNow.addingTimeInterval(36 * 3600)

        let viewModel = CoachAvailabilityViewModel(
            authService: mockService,
            initialStartTime: validStartDate
        )

        viewModel.selectedDurationMinutes = 60
        viewModel.offerAsFreeAnonymousSession = true
        #expect(viewModel.addDraftSlot(referenceDate: referenceNow) == true)

        // Attempt to add overlapping slot starting 30 mins after validStartDate
        viewModel.selectedStartTime = validStartDate.addingTimeInterval(30 * 60)
        #expect(viewModel.addDraftSlot(referenceDate: referenceNow) == false)
        #expect(viewModel.errorMessage == "This time window overlaps with another drafted slot.")

        // Remove the drafted slot
        if let firstSlotId = viewModel.draftedSlots.first?.id {
            viewModel.removeDraftSlot(id: firstSlotId)
        }
        #expect(viewModel.draftedSlots.isEmpty)
    }

    @Test("FreePledgeProgressRingView and CoachAvailabilityManagerView initialize with Tranquil design tokens")
    @MainActor
    func testViewsInitialize() {
        let ringView = FreePledgeProgressRingView(
            pledgedMinutes: 30,
            targetMinutes: 60,
            progress: 0.5,
            isSatisfied: false
        )
        #expect(ringView.pledgedMinutes == 30)
        #expect(ringView.progress == 0.5)

        let viewModel = CoachAvailabilityViewModel(authService: MockCoachAvailabilityAuthService())
        let managerView = CoachAvailabilityManagerView(
            viewModel: viewModel,
            coachId: UUID(),
            coachTimezoneIdentifier: "America/New_York"
        )
        #expect(managerView.coachTimezoneIdentifier == "America/New_York")
        let mirror = Mirror(reflecting: managerView)
        #expect(!mirror.children.isEmpty)
    }

    @Test("RemoteAuthService publishes and fetches coach availabilities via MockURLProtocol")
    func testRemoteAuthServiceAvailabilityEndpoints() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AvailabilityMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let identityService = IdentityService(serviceIdentifier: "com.anony.mobile.test.availabilities")
        _ = identityService.saveSession(
            token: "coach-jwt-token",
            alias: "CalmWillow10",
            email: "coach@anony.app",
            role: "COACH"
        )

        let authService = RemoteAuthService(
            baseURL: URL(string: "http://127.0.0.1:8080")!,
            session: session,
            identityService: identityService
        )

        let coachId = UUID(uuidString: "22222222-3333-4444-5555-666666666666")!
        let slotId = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let startAt = Date(timeIntervalSince1970: 1_809_957_600)

        AvailabilityMockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/api/v1/coaches/me/availabilities")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer coach-jwt-token")

            let responseJSON = """
            [
              {
                "slotId": "\(slotId.uuidString)",
                "coachId": "\(coachId.uuidString)",
                "startAt": "2027-05-10T14:00:00Z",
                "endAt": "2027-05-10T15:00:00Z",
                "durationMinutes": 60,
                "isFreePledge": true,
                "is_free_pledge": true,
                "isBooked": false
              }
            ]
            """.data(using: .utf8)!
            let httpResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (httpResponse, responseJSON)
        }

        let payload = CoachAvailabilitySlotPayload(
            id: slotId,
            startAt: startAt,
            durationMinutes: 60,
            isFreePledge: true
        )
        let published = try await authService.publishCoachAvailabilities(slots: [payload])
        #expect(published.count == 1)
        #expect(published[0].slotId == slotId)
        #expect(published[0].isFreePledge == true)

        AvailabilityMockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/api/v1/coaches/\(coachId.uuidString)/availabilities")
            #expect(request.httpMethod == "GET")
            let responseJSON = """
            [
              {
                "slotId": "\(slotId.uuidString)",
                "coachId": "\(coachId.uuidString)",
                "startAt": "2027-05-10T14:00:00Z",
                "endAt": "2027-05-10T15:00:00Z",
                "durationMinutes": 60,
                "isFreePledge": true,
                "isBooked": false
              }
            ]
            """.data(using: .utf8)!
            let httpResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (httpResponse, responseJSON)
        }

        let fetched = try await authService.fetchCoachAvailabilities(
            coachId: coachId,
            from: startAt.addingTimeInterval(-3600),
            to: startAt.addingTimeInterval(7200)
        )
        #expect(fetched.count == 1)
        #expect(fetched[0].coachId == coachId)

        _ = identityService.clearSession()
    }
}
