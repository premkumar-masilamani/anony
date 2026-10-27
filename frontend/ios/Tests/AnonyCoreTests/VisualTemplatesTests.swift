import Testing
import SwiftUI
@testable import AnonyCore

@Suite("VisualTemplatesTests")
struct VisualTemplatesTests {

    @Test("CoachingSessionView template instantiates cleanly")
    func coachingSessionViewInstantiation() {
        let view = VisualTemplates.CoachingSessionView()
        #expect(String(describing: type(of: view)) == "CoachingSessionView")
    }

    @Test("DesignSystemGalleryView template instantiates cleanly")
    func designSystemGalleryViewInstantiation() {
        let gallery = VisualTemplates.DesignSystemGalleryView()
        #expect(String(describing: type(of: gallery)) == "DesignSystemGalleryView")
    }
}
