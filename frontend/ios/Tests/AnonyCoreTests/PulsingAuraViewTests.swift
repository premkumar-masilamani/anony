import Testing
import SwiftUI
@testable import AnonyCore

@Suite("PulsingAuraViewTests")
struct PulsingAuraViewTests {

    @Test("Default aura parameters adhere to calming breathing cycle")
    func defaultParameters() {
        let aura = PulsingAuraView()
        #expect(aura.diameter == 80)
        #expect(aura.cycleDuration == 3.5)
        #expect(aura.scaleRange == (0.92...1.15))
    }

    @Test("Custom aura parameters initialization")
    func customParameters() {
        let customAura = PulsingAuraView(
            color: ColorPalette.calmingCyan,
            diameter: 120,
            cycleDuration: 4.0,
            scaleRange: 0.9...1.25
        )
        #expect(customAura.color == ColorPalette.calmingCyan)
        #expect(customAura.diameter == 120)
        #expect(customAura.cycleDuration == 4.0)
        #expect(customAura.scaleRange == (0.9...1.25))
    }
}
