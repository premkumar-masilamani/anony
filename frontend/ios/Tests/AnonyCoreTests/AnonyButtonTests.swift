import Testing
import SwiftUI
@testable import AnonyCore

@Suite("AnonyButtonTests")
struct AnonyButtonTests {

    @Test("Button variant initialization")
    func buttonVariants() {
        let primaryBtn = AnonyButton(title: "Continue", variant: .primary) {}
        let secondaryBtn = AnonyButton(title: "Cancel", variant: .secondary) {}
        let ghostBtn = AnonyButton(title: "Skip", variant: .ghost) {}

        #expect(primaryBtn.variant == .primary)
        #expect(secondaryBtn.variant == .secondary)
        #expect(ghostBtn.variant == .ghost)
    }

    @Test("Button size presets")
    func buttonSizes() {
        let smallBtn = AnonyButton(title: "Small", size: .small) {}
        let medBtn = AnonyButton(title: "Medium", size: .medium) {}
        let largeBtn = AnonyButton(title: "Large", size: .large) {}

        #expect(smallBtn.size == .small)
        #expect(medBtn.size == .medium)
        #expect(largeBtn.size == .large)
    }

    @Test("Button states (loading and disabled)")
    func buttonStates() {
        let loadingBtn = AnonyButton(title: "Connecting", isLoading: true) {}
        let disabledBtn = AnonyButton(title: "Unavailable", isDisabled: true) {}

        #expect(loadingBtn.isLoading == true)
        #expect(disabledBtn.isDisabled == true)
    }

    @Test("Button with system icon")
    func buttonWithIcon() {
        let iconBtn = AnonyButton(title: "Secure Session", systemImage: "lock.shield", variant: .primary) {}
        #expect(iconBtn.systemImage == "lock.shield")
        #expect(iconBtn.title == "Secure Session")
    }
}
