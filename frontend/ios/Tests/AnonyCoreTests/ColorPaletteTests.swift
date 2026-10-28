import Testing
import SwiftUI
@testable import AnonyCore

@Suite("ColorPaletteTests")
struct ColorPaletteTests {
    
    @Test("Palette colors exist and match tranquil hex specs")
    func paletteColorsExist() {
        // Test exact RGB initialization values
        let slate = ColorPalette.midnightSlate
        let charcoal = ColorPalette.warmCharcoal
        let card = ColorPalette.elevatedCard
        let sage = ColorPalette.sageGreen
        let cyan = ColorPalette.calmingCyan
        let lavender = ColorPalette.mutedLavender

        #expect(slate == Color(red: 11 / 255, green: 15 / 255, blue: 25 / 255))
        #expect(charcoal == Color(red: 22 / 255, green: 27 / 255, blue: 38 / 255))
        #expect(card == Color(red: 30 / 255, green: 37 / 255, blue: 54 / 255))
        #expect(sage == Color(red: 52 / 255, green: 211 / 255, blue: 153 / 255))
        #expect(cyan == Color(red: 56 / 255, green: 189 / 255, blue: 248 / 255))
        #expect(lavender == Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255))
    }

    @Test("Hex initializer parses correctly")
    func hexInitializerMatchesExpectedRGB() {
        let sageHex = Color(hex: "#34D399")
        let cyanHex = Color(hex: "#38BDF8")
        let slateHex = Color(hex: "#0B0F19")
        
        #expect(sageHex == Color(hex: "34D399"))
        #expect(cyanHex == Color(hex: "38BDF8"))
        #expect(slateHex == Color(hex: "0B0F19"))
    }

    @Test("Semantic colors are defined")
    func semanticColorsExist() {
        #expect(ColorPalette.textPrimary == Color.white)
        #expect(ColorPalette.textSecondary == Color(red: 203 / 255, green: 213 / 255, blue: 225 / 255))
        #expect(ColorPalette.textMuted == Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255))
    }

    @Test("Tranquil gradients exist")
    func tranquilGradientsExist() {
        let background = ColorPalette.backgroundGradient
        let auraGlow = ColorPalette.auraGlowGradient

        #expect(String(describing: background).contains("LinearGradient"))
        #expect(String(describing: auraGlow).contains("RadialGradient"))
    }

    @Test("Distinct coach theme tokens and gradients exist")
    func coachThemeTokensAndGradientsExist() {
        #expect(ColorPalette.coachPrimaryAccent == ColorPalette.sageGreen)
        #expect(ColorPalette.coachSecondaryAccent == ColorPalette.mutedLavender)
        #expect(ColorPalette.coachCardBorder == ColorPalette.sageGreen.opacity(0.22))
        #expect(String(describing: ColorPalette.coachBackgroundGradient).contains("LinearGradient"))
        #expect(String(describing: ColorPalette.coachAuraGlowGradient).contains("RadialGradient"))
    }
}
