import Testing
import SwiftUI
@testable import AnonyCore

@Suite("GlassCardTests")
struct GlassCardTests {

    @Test("GlassCard default parameters")
    func defaultParameters() {
        let card = GlassCard {
            Text("Sample Content")
        }
        #expect(card.cornerRadius == 16)
        #expect(card.style == .standard)
    }

    @Test("GlassCard style variants")
    func styles() {
        let standardCard = GlassCard(style: .standard) { Text("Standard") }
        let elevatedCard = GlassCard(style: .elevated) { Text("Elevated") }
        let highlightedCard = GlassCard(style: .highlighted(ColorPalette.sageGreen), cornerRadius: 20) {
            Text("Highlighted")
        }

        #expect(standardCard.style == .standard)
        #expect(elevatedCard.style == .elevated)
        #expect(highlightedCard.cornerRadius == 20)
    }
}
