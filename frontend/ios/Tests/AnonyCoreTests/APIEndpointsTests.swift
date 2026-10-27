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
        #expect(APIEndpoints.coaches == "/api/v1/coaches")
        #expect(APIEndpoints.favorites == "/api/v1/coaches/favorites")
        #expect(APIEndpoints.blindMatch == "/api/v1/match/blind")

        let testId = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        #expect(APIEndpoints.coachDetails(id: testId) == "/api/v1/coaches/11111111-2222-3333-4444-555555555555")
        #expect(APIEndpoints.coachFavorite(id: testId) == "/api/v1/coaches/11111111-2222-3333-4444-555555555555/favorite")
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
