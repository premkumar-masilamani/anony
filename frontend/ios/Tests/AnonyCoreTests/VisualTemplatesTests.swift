import Testing
import SwiftUI
@testable import AnonyCore

@Suite("VisualTemplatesTests")
struct VisualTemplatesTests {

    @Test("SanctuaryView template instantiates cleanly")
    func sanctuaryViewInstantiation() {
        let view = VisualTemplates.SanctuaryView()
        #expect(String(describing: type(of: view)) == "SanctuaryView")
    }

    @Test("DesignSystemGalleryView template instantiates cleanly")
    func designSystemGalleryViewInstantiation() {
        let gallery = VisualTemplates.DesignSystemGalleryView()
        #expect(String(describing: type(of: gallery)) == "DesignSystemGalleryView")
    }
}
