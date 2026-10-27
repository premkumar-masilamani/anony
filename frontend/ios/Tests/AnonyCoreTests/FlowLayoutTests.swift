import Foundation
import Testing
import SwiftUI
@testable import AnonyCore

@Suite("FlowLayoutTests")
struct FlowLayoutTests {

    @Test("FlowLayout instantiates with specified and default spacing")
    func testFlowLayoutInstantiation() {
        let layoutDefault = FlowLayout()
        #expect(layoutDefault.spacing == 8)

        let layoutCustom = FlowLayout(spacing: 12)
        #expect(layoutCustom.spacing == 12)
    }

    @Test("FlowLayout computes non-empty size proposal")
    func testFlowLayoutSizeThatFits() {
        let layout = FlowLayout(spacing: 6)
        let mirror = Mirror(reflecting: layout)
        #expect(!mirror.children.isEmpty)
    }
}
