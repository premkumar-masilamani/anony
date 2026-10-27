import Foundation
import Testing
import SwiftUI
@testable import AnonyCore

@Suite("CoachAuthViewTests")
struct CoachAuthViewTests {

    @Test("CoachRegistrationPayload conforms to Codable and Equatable with extended coach fields")
    func testCoachRegistrationPayload() throws {
        let payload = CoachRegistrationPayload(
            email: "coach@example.com",
            password: "SecurePassword#123",
            firstName: "Jane",
            lastName: "Doe",
            photoUrl: "https://example.com/photo.jpg",
            gender: "FEMALE",
            countryCode: "US",
            icfLevel: "PCC",
            icfAcc: false,
            icfPcc: true,
            icfMcc: false,
            icfActc: false,
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
        #expect(decoded.photoUrl == "https://example.com/photo.jpg")
        #expect(decoded.gender == "FEMALE")
        #expect(decoded.countryCode == "US")
        #expect(decoded.icfLevel == "PCC")
        #expect(decoded.icfPcc == true)
        #expect(decoded.domainCodes == ["CAREER", "BURNOUT"])
        #expect(decoded.hourlyRate == 175.0)
    }

    @Test("CoachUpdatePayload conforms to Codable and Equatable")
    func testCoachUpdatePayload() throws {
        let payload = CoachUpdatePayload(
            firstName: "Maya",
            lastName: "Raman",
            photoUrl: "https://example.com/maya.jpg",
            gender: "FEMALE",
            countryCode: "IN",
            timezone: "Asia/Kolkata",
            biography: "Leadership mentor.",
            icfLevel: "MCC",
            icfAcc: true,
            icfPcc: true,
            icfMcc: true,
            icfActc: false,
            credentialDetails: "Certificates verified",
            domainCodes: ["LEADERSHIP"],
            hourlyRate: 220.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CoachUpdatePayload.self, from: data)

        #expect(decoded.firstName == "Maya")
        #expect(decoded.lastName == "Raman")
        #expect(decoded.icfMcc == true)
        #expect(decoded.countryCode == "IN")
        #expect(decoded.hourlyRate == 220.0)
    }

    @Test("CoachProfileResponse conforms to Codable and Identifiable with extended fields")
    func testCoachProfileResponse() throws {
        let coachId = UUID()
        let userId = UUID()
        let profile = CoachProfileResponse(
            coachId: coachId,
            userId: userId,
            email: "maya.raman@example.com",
            firstName: "Maya",
            lastName: "Raman",
            photoUrl: "https://example.com/maya.jpg",
            gender: "FEMALE",
            countryCode: "IN",
            timezone: "Asia/Kolkata",
            biography: "Bio",
            icfLevel: "PCC",
            icfAcc: false,
            icfPcc: true,
            icfMcc: false,
            icfActc: false,
            credentialDetails: "ICF-PCC-1029",
            hourlyRate: 180.0,
            isVerified: false,
            isOnboarded: false,
            domainCodes: ["CAREER"]
        )

        #expect(profile.id == coachId)
        #expect(profile.isVerified == false)
        #expect(profile.icfLevel == "PCC")
        #expect(profile.photoUrl == "https://example.com/maya.jpg")
        #expect(profile.gender == "FEMALE")
        #expect(profile.countryCode == "IN")
        #expect(profile.hourlyRate == 180.0)
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

    @Test("CoachProfileEditView instantiates cleanly and resolves country options")
    func testCoachProfileEditViewInstantiation() {
        let profile = CoachProfileResponse(
            coachId: UUID(),
            userId: UUID(),
            email: "coach@example.com",
            firstName: "Jane",
            lastName: "Doe",
            countryCode: "IN",
            timezone: "Asia/Kolkata",
            icfLevel: "ACC",
            icfAcc: true,
            icfPcc: false,
            icfMcc: false,
            icfActc: false,
            isVerified: false,
            isOnboarded: false
        )
        let view = CoachProfileEditView(profile: profile, onSaved: { _ in })
        let mirror = Mirror(reflecting: view)
        #expect(!mirror.children.isEmpty)
    }

    @Test("CoachProfileEditView handles default US fallback when countryCode is nil")
    func testCoachProfileEditViewDefaultCountry() {
        let profile = CoachProfileResponse(
            coachId: UUID(),
            userId: UUID(),
            email: "coach@example.com",
            firstName: "John",
            lastName: "Smith",
            countryCode: nil,
            timezone: "America/New_York",
            icfLevel: "PCC",
            icfAcc: true,
            icfPcc: true,
            icfMcc: false,
            icfActc: false,
            isVerified: false,
            isOnboarded: false
        )
        let view = CoachProfileEditView(profile: profile, onSaved: { _ in })
        let mirror = Mirror(reflecting: view)
        #expect(!mirror.children.isEmpty)
    }

    @Test("CoachDashboardView instantiates cleanly")
    func testCoachDashboardViewInstantiation() {
        let view = CoachDashboardView(
            coachEmail: "coach@example.com",
            onSignOut: {}
        )

        #expect(view.coachEmail == "coach@example.com")
    }

    @Test("RegistrationView defaults to sign in mode")
    func testRegistrationViewDefaultsToSignIn() {
        let view = RegistrationView(onSuccess: { _ in })
        let mirror = Mirror(reflecting: view)
        #expect(!mirror.children.isEmpty)
    }

    @Test("RegistrationView accepts initialMode parameter")
    func testRegistrationViewInitialMode() {
        let registerView = RegistrationView(initialMode: .register, onSuccess: { _ in })
        let signInView = RegistrationView(initialMode: .signIn, onSuccess: { _ in })
        #expect(!Mirror(reflecting: registerView).children.isEmpty)
        #expect(!Mirror(reflecting: signInView).children.isEmpty)
    }
}
