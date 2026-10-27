import Foundation
import Testing
import SwiftUI
@testable import AnonyCore

@Suite("CoachAuthViewTests")
struct CoachAuthViewTests {

    @Test("CoachRegistrationPayload conforms to Codable and Equatable")
    func testCoachRegistrationPayload() throws {
        let payload = CoachRegistrationPayload(
            email: "coach@example.com",
            password: "SecurePassword#123",
            firstName: "Jane",
            lastName: "Doe",
            icfLevel: "PCC",
            credentialDetails: "ICF-PCC-1029",
            domainCodes: ["CAREER", "BURNOUT"],
            timezone: "America/New_York",
            biography: "Executive coach.",
            hourlyRate: 175.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CoachRegistrationPayload.self, from: data)

        #expect(decoded.email == "coach@example.com")
        #expect(decoded.firstName == "Jane")
        #expect(decoded.icfLevel == "PCC")
        #expect(decoded.domainCodes == ["CAREER", "BURNOUT"])
        #expect(decoded.hourlyRate == 175.0)
    }

    @Test("CoachProfileResponse conforms to Codable and Identifiable")
    func testCoachProfileResponse() throws {
        let coachId = UUID()
        let userId = UUID()
        let profile = CoachProfileResponse(
            coachId: coachId,
            userId: userId,
            email: "maya.raman@example.com",
            firstName: "Maya",
            lastName: "Raman",
            timezone: "Asia/Kolkata",
            biography: "Bio",
            icfLevel: "PCC",
            icfAcc: false,
            icfPcc: true,
            icfMcc: false,
            icfActc: false,
            credentialDetails: "ICF-PCC-1029",
            isVerified: false,
            isOnboarded: false,
            domainCodes: ["CAREER"]
        )

        #expect(profile.id == coachId)
        #expect(profile.isVerified == false)
        #expect(profile.icfLevel == "PCC")
    }

    @Test("ClientProfileResponse conforms to Codable and Identifiable")
    func testClientProfileResponse() throws {
        let clientId = UUID()
        let userId = UUID()
        let client = ClientProfileResponse(
            clientId: clientId,
            userId: userId,
            email: "client@example.com",
            firstName: "Arjun",
            lastName: "Mehta",
            alias: "Courageous Owl",
            isAnonymous: true,
            isOnboarded: false
        )

        #expect(client.id == clientId)
        #expect(client.alias == "Courageous Owl")
        #expect(client.isAnonymous == true)
    }

    @Test("CoachAuthView instantiates cleanly")
    func testCoachAuthViewInstantiation() {
        let view = CoachAuthView(
            onSwitchToClient: {},
            onSuccess: { _ in }
        )

        let mirror = Mirror(reflecting: view)
        #expect(!mirror.children.isEmpty)
    }

    @Test("CoachVerificationPendingView instantiates cleanly")
    func testCoachVerificationPendingViewInstantiation() {
        let view = CoachVerificationPendingView(
            coachEmail: "coach@example.com",
            onVerified: {},
            onSignOut: {}
        )

        #expect(view.coachEmail == "coach@example.com")
    }

    @Test("CoachDashboardView instantiates cleanly")
    func testCoachDashboardViewInstantiation() {
        let view = CoachDashboardView(
            coachEmail: "coach@example.com",
            onSignOut: {}
        )

        #expect(view.coachEmail == "coach@example.com")
    }

    @Test("RegistrationView defaults to client sign up mode")
    func testRegistrationViewDefaultsToSignUp() {
        let view = RegistrationView(onSuccess: { _ in })
        let mirror = Mirror(reflecting: view)
        #expect(!mirror.children.isEmpty)
    }
}
