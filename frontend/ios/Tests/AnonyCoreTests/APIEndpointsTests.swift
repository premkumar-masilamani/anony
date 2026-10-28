import Foundation
import Testing
@testable import AnonyCore

@Suite("APIEndpointsTests")
struct APIEndpointsTests {

    @Test("APIConfig baseURL is valid and non-empty")
    func testAPIConfigBaseURL() {
        let baseURL = APIConfig.defaultBaseURL
        #expect(baseURL.scheme == "https")
        #expect(baseURL.host == "api.anony.app")
    }

    @Test("APIEndpoints path constants adhere to v1 REST contracts")
    func testAPIEndpointPaths() {
        #expect(APIEndpoints.register == "/api/v1/auth/register")
        #expect(APIEndpoints.login == "/api/v1/auth/login")
        #expect(APIEndpoints.logout == "/api/v1/auth/logout")
        #expect(APIEndpoints.clientsMe == "/api/v1/clients/me")
        #expect(APIEndpoints.coaches == "/api/v1/coaches")
        #expect(APIEndpoints.coachesMe == "/api/v1/coaches/me")
        #expect(APIEndpoints.favorites == "/api/v1/coaches/favorites")
        #expect(APIEndpoints.sessions == "/api/v1/sessions")
        #expect(APIEndpoints.blindMatch == "/api/v1/sessions")
        #expect(APIEndpoints.bookings == "/api/v1/sessions")

        let testId = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        #expect(APIEndpoints.coachDetails(id: testId) == "/api/v1/coaches/11111111-2222-3333-4444-555555555555")
        #expect(APIEndpoints.coachFavorite(id: testId) == "/api/v1/coaches/11111111-2222-3333-4444-555555555555/favorite")
        #expect(APIEndpoints.coachSlots(id: testId) == "/api/v1/coaches/11111111-2222-3333-4444-555555555555/slots")
        #expect(APIEndpoints.coachAvailabilities(id: testId) == "/api/v1/coaches/11111111-2222-3333-4444-555555555555/availabilities")
        #expect(APIEndpoints.sessionDetails(id: testId) == "/api/v1/sessions/11111111-2222-3333-4444-555555555555")
        #expect(APIEndpoints.sessionJoinToken(id: testId) == "/api/v1/sessions/11111111-2222-3333-4444-555555555555/join-token")
        #expect(APIEndpoints.sessionReflection(id: testId) == "/api/v1/sessions/11111111-2222-3333-4444-555555555555/reflection")
        #expect(APIEndpoints.sessionTestimonial(id: testId) == "/api/v1/sessions/11111111-2222-3333-4444-555555555555/testimonial")
    }

    @Test("APIEndpoints resolves full URL correctly")
    func testAPIEndpointURLResolution() {
        let url = APIEndpoints.url(for: APIEndpoints.coaches)
        #expect(url.absoluteString == "https://api.anony.app/api/v1/coaches")

        let testId = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let favUrl = APIEndpoints.url(for: APIEndpoints.coachFavorite(id: testId))
        #expect(favUrl.absoluteString == "https://api.anony.app/api/v1/coaches/11111111-2222-3333-4444-555555555555/favorite")
    }
}
