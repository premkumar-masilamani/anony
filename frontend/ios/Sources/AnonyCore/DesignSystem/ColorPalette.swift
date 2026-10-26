import SwiftUI

public enum ColorPalette {
    // Core Tranquil Theme Palette
    public static let midnightSlate = Color(red: 11 / 255, green: 15 / 255, blue: 25 / 255)   // #0B0F19
    public static let warmCharcoal  = Color(red: 22 / 255, green: 27 / 255, blue: 38 / 255)   // #161B26
    public static let elevatedCard  = Color(red: 30 / 255, green: 37 / 255, blue: 54 / 255)   // #1E2536
    public static let sageGreen     = Color(red: 52 / 255, green: 211 / 255, blue: 153 / 255) // #34D399
    public static let calmingCyan   = Color(red: 56 / 255, green: 189 / 255, blue: 248 / 255) // #38BDF8
    public static let mutedLavender = Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255)// #A78BFA

    // Semantic Text & Border Colors
    public static let textPrimary   = Color.white
    public static let textSecondary = Color(red: 203 / 255, green: 213 / 255, blue: 225 / 255) // Slate 300
    public static let textMuted     = Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255) // Slate 400
    public static let cardBorder    = Color.white.opacity(0.08)

    // Tranquil Gradients
    public static let sanctuaryGradient = LinearGradient(
        colors: [midnightSlate, warmCharcoal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let auraGlowGradient = RadialGradient(
        colors: [
            calmingCyan.opacity(0.35),
            sageGreen.opacity(0.15),
            Color.clear
        ],
        center: .center,
        startRadius: 5,
        endRadius: 90
    )
}

// MARK: - Color Hex Initializer
public extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
