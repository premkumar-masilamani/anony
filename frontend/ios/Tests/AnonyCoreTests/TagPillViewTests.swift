import Testing
import SwiftUI
@testable import AnonyCore

@Suite("TagPillViewTests")
struct TagPillViewTests {

    @Test("TagPill variant assignment")
    func tagPillVariants() {
        let cyanPill = TagPillView(text: "Encrypted", variant: .cyan)
        let sagePill = TagPillView(text: "Verified", variant: .sage)
        let lavenderPill = TagPillView(text: "Reflective", variant: .lavender)
        let neutralPill = TagPillView(text: "Private", variant: .neutral)

        #expect(cyanPill.variant == .cyan)
        #expect(sagePill.variant == .sage)
        #expect(lavenderPill.variant == .lavender)
        #expect(neutralPill.variant == .neutral)
    }

    @Test("TagPill with system image")
    func tagPillWithSystemImage() {
        let iconPill = TagPillView(text: "Audio Only", systemImage: "mic.fill", variant: .sage)
        #expect(iconPill.text == "Audio Only")
        #expect(iconPill.systemImage == "mic.fill")
    }
}
