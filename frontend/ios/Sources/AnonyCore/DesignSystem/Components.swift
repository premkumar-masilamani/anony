import SwiftUI

// MARK: - AnonyButton
public struct AnonyButton: View {
    public enum Variant: Sendable, Equatable {
        case primary
        case secondary
        case ghost
    }

    public enum Size: Sendable, Equatable {
        case small
        case medium
        case large

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 18
            case .large: return 24
            }
        }

        var font: Font {
            switch self {
            case .small: return .subheadline.weight(.medium)
            case .medium: return .headline.weight(.semibold)
            case .large: return .title3.weight(.bold)
            }
        }
    }

    public let title: String
    public let systemImage: String?
    public let variant: Variant
    public let size: Size
    public let isLoading: Bool
    public let isDisabled: Bool
    public let action: () -> Void

    public init(
        title: String,
        systemImage: String? = nil,
        variant: Variant = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: {
            guard !isLoading && !isDisabled else { return }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(size == .small ? 0.8 : 1.0)
                } else {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                            .font(size.font)
                    }
                    Text(title)
                        .font(size.font)
                }
            }
            .foregroundColor(foregroundColor)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: size == .large ? .infinity : nil)
            .background(backgroundView)
            .cornerRadius(12)
            .overlay(borderOverlay)
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
            .opacity(isDisabled ? 0.45 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isLoading)
        }
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return ColorPalette.midnightSlate
        case .secondary:
            return ColorPalette.calmingCyan
        case .ghost:
            return ColorPalette.textSecondary
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            ColorPalette.calmingCyan
        case .secondary:
            ColorPalette.elevatedCard
        case .ghost:
            Color.clear
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .primary:
            EmptyView()
        case .secondary:
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.calmingCyan.opacity(0.3), lineWidth: 1)
        case .ghost:
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.cardBorder, lineWidth: 1)
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary:
            return ColorPalette.calmingCyan.opacity(0.25)
        case .secondary, .ghost:
            return Color.clear
        }
    }
}

// MARK: - GlassCard
public struct GlassCard<Content: View>: View {
    public enum Style: Sendable, Equatable {
        case standard
        case elevated
        case highlighted(Color)
    }

    public let style: Style
    public let cornerRadius: CGFloat
    public let content: Content

    public init(
        style: Style = .standard,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .background(cardBackground)
            .cornerRadius(cornerRadius)
            .overlay(cardBorder)
    }

    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .standard:
            ColorPalette.elevatedCard.opacity(0.85)
        case .elevated:
            ColorPalette.warmCharcoal
        case .highlighted:
            ColorPalette.elevatedCard
        }
    }

    @ViewBuilder
    private var cardBorder: some View {
        switch style {
        case .standard, .elevated:
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(ColorPalette.cardBorder, lineWidth: 1)
        case .highlighted(let accentColor):
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(accentColor.opacity(0.4), lineWidth: 1.5)
        }
    }
}

// MARK: - PulsingAuraView
public struct PulsingAuraView: View {
    public let color: Color
    public let diameter: CGFloat
    public let cycleDuration: Double
    public let scaleRange: ClosedRange<CGFloat>

    @State private var isPulsing = false

    public init(
        color: Color = ColorPalette.sageGreen,
        diameter: CGFloat = 80,
        cycleDuration: Double = 3.5,
        scaleRange: ClosedRange<CGFloat> = 0.92...1.15
    ) {
        self.color = color
        self.diameter = diameter
        self.cycleDuration = cycleDuration
        self.scaleRange = scaleRange
    }

    public var body: some View {
        ZStack {
            // Outer tranquil breathing ring
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: diameter * 1.3, height: diameter * 1.3)
                .scaleEffect(isPulsing ? scaleRange.upperBound : scaleRange.lowerBound)
                .opacity(isPulsing ? 0.35 : 0.1)

            // Inner core glow
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: diameter, height: diameter)
                .scaleEffect(isPulsing ? 1.05 : 0.95)
                .opacity(isPulsing ? 0.5 : 0.2)
        }
        .animation(
            Animation.easeInOut(duration: cycleDuration).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - TagPillView
public struct TagPillView: View {
    public enum Variant: Sendable, Equatable {
        case cyan
        case sage
        case lavender
        case neutral

        var foregroundColor: Color {
            switch self {
            case .cyan: return ColorPalette.calmingCyan
            case .sage: return ColorPalette.sageGreen
            case .lavender: return ColorPalette.mutedLavender
            case .neutral: return ColorPalette.textSecondary
            }
        }

        var backgroundColor: Color {
            switch self {
            case .cyan: return ColorPalette.calmingCyan.opacity(0.12)
            case .sage: return ColorPalette.sageGreen.opacity(0.12)
            case .lavender: return ColorPalette.mutedLavender.opacity(0.12)
            case .neutral: return ColorPalette.warmCharcoal
            }
        }

        var borderColor: Color {
            switch self {
            case .cyan: return ColorPalette.calmingCyan.opacity(0.3)
            case .sage: return ColorPalette.sageGreen.opacity(0.3)
            case .lavender: return ColorPalette.mutedLavender.opacity(0.3)
            case .neutral: return ColorPalette.cardBorder
            }
        }
    }

    public let text: String
    public let systemImage: String?
    public let variant: Variant

    public init(
        text: String,
        systemImage: String? = nil,
        variant: Variant = .cyan
    ) {
        self.text = text
        self.systemImage = systemImage
        self.variant = variant
    }

    public var body: some View {
        HStack(spacing: 5) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(variant.backgroundColor)
        .foregroundColor(variant.foregroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(variant.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - AvatarCircleView (Procedural Zero-PII)
public struct AvatarCircleView: View {
    public enum Size: Sendable, Equatable {
        case small       // 32
        case medium      // 44
        case large       // 64
        case extraLarge  // 88

        public var diameter: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 64
            case .extraLarge: return 88
            }
        }
    }

    public struct ProceduralParameters: Sendable, Equatable {
        public static let curatedSymbols: [String] = [
            "bird.fill",
            "hare.fill",
            "tortoise.fill",
            "fish.fill",
            "pawprint.fill",
            "tree.fill",
            "leaf.fill",
            "drop.fill",
            "wind",
            "cloud.fill",
            "mountain.2.fill",
            "moon.stars.fill"
        ]

        private static let nounSymbolMappings: [(keyword: String, symbol: String)] = [
            ("Owl", "bird.fill"),
            ("Finch", "bird.fill"),
            ("Falcon", "bird.fill"),
            ("Bird", "bird.fill"),
            ("Hare", "hare.fill"),
            ("Tortoise", "tortoise.fill"),
            ("Fish", "fish.fill"),
            ("Fox", "pawprint.fill"),
            ("Wolf", "pawprint.fill"),
            ("Otter", "pawprint.fill"),
            ("Willow", "tree.fill"),
            ("Pine", "tree.fill"),
            ("Meadow", "leaf.fill"),
            ("Leaf", "leaf.fill"),
            ("River", "drop.fill"),
            ("Creek", "drop.fill"),
            ("Breeze", "wind"),
            ("Cloud", "cloud.fill"),
            ("Peak", "mountain.2.fill"),
            ("Stone", "mountain.2.fill"),
            ("Star", "moon.stars.fill"),
            ("Moon", "moon.stars.fill")
        ]

        public let primaryColorIndex: Int
        public let secondaryColorIndex: Int
        public let motifIndex: Int
        public let rotationAngle: Double
        public let symbolName: String

        public static func generate(from seed: String) -> ProceduralParameters {
            var hash: UInt64 = 5381
            for byte in seed.utf8 {
                hash = ((hash << 5) &+ hash) &+ UInt64(byte)
            }

            let primary = Int(hash % 3) // 0: sageGreen, 1: calmingCyan, 2: mutedLavender
            let secondary = Int((hash / 7) % 3)
            let safeSecondary = (primary == secondary) ? ((secondary + 1) % 3) : secondary
            let motif = Int((hash / 13) % 3) // 0: Concentric calm, 1: Geometric arcs, 2: Serene diamond
            let angle = Double((hash / 29) % 360)
            let resolvedSymbol = resolveSymbolName(from: seed, hash: hash)

            return ProceduralParameters(
                primaryColorIndex: primary,
                secondaryColorIndex: safeSecondary,
                motifIndex: motif,
                rotationAngle: angle,
                symbolName: resolvedSymbol
            )
        }

        private static func resolveSymbolName(from seed: String, hash: UInt64) -> String {
            for mapping in nounSymbolMappings {
                if seed.localizedCaseInsensitiveContains(mapping.keyword) {
                    return mapping.symbol
                }
            }
            let fallbackIndex = Int((hash / 37) % UInt64(curatedSymbols.count))
            return curatedSymbols[fallbackIndex]
        }
    }

    public let seed: String
    public let size: Size
    public let showAura: Bool
    public let params: ProceduralParameters

    public init(
        seed: String,
        size: Size = .medium,
        showAura: Bool = false
    ) {
        self.seed = seed
        self.size = size
        self.showAura = showAura
        self.params = ProceduralParameters.generate(from: seed)
    }

    private var paletteColors: [Color] {
        [ColorPalette.sageGreen, ColorPalette.calmingCyan, ColorPalette.mutedLavender]
    }

    private var primaryColor: Color {
        paletteColors[params.primaryColorIndex % paletteColors.count]
    }

    private var secondaryColor: Color {
        paletteColors[params.secondaryColorIndex % paletteColors.count]
    }

    public var body: some View {
        ZStack {
            if showAura {
                PulsingAuraView(
                    color: primaryColor,
                    diameter: size.diameter * 1.15,
                    cycleDuration: 3.5
                )
            }

            // Outer base disc
            Circle()
                .fill(
                    LinearGradient(
                        colors: [ColorPalette.elevatedCard, ColorPalette.warmCharcoal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.diameter, height: size.diameter)
                .overlay(
                    Circle()
                        .stroke(primaryColor.opacity(0.35), lineWidth: 1.5)
                )

            // Inner procedural zero-PII geometric motifs + native iOS SF Symbol glyph
            Group {
                switch params.motifIndex {
                case 0:
                    // Concentric soothing ring backdrop
                    Circle()
                        .stroke(secondaryColor.opacity(0.28), lineWidth: size.diameter * 0.06)
                        .frame(width: size.diameter * 0.72, height: size.diameter * 0.72)
                case 1:
                    // Soft interlocking crescent arcs backdrop
                    ZStack {
                        Circle()
                            .trim(from: 0.1, to: 0.6)
                            .stroke(primaryColor.opacity(0.35), style: StrokeStyle(lineWidth: size.diameter * 0.06, lineCap: .round))
                            .frame(width: size.diameter * 0.74, height: size.diameter * 0.74)
                            .rotationEffect(.degrees(params.rotationAngle))
                        Circle()
                            .trim(from: 0.4, to: 0.9)
                            .stroke(secondaryColor.opacity(0.35), style: StrokeStyle(lineWidth: size.diameter * 0.06, lineCap: .round))
                            .frame(width: size.diameter * 0.62, height: size.diameter * 0.62)
                            .rotationEffect(.degrees(-params.rotationAngle))
                    }
                default:
                    // Serene rotated diamond halo backdrop
                    RoundedRectangle(cornerRadius: size.diameter * 0.12)
                        .stroke(secondaryColor.opacity(0.28), lineWidth: size.diameter * 0.05)
                        .frame(width: size.diameter * 0.56, height: size.diameter * 0.56)
                        .rotationEffect(.degrees(45 + params.rotationAngle))
                }
            }

            Image(systemName: params.symbolName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(primaryColor, secondaryColor)
                .font(.system(size: size.diameter * 0.42, weight: .medium))
        }
        .frame(width: size.diameter, height: size.diameter)
        .accessibilityLabel("Procedural avatar for \(seed)")
    }

    /// Renders the procedural avatar view into a native CGImage using SwiftUI's built-in ImageRenderer.
    @MainActor
    public func renderCGImage(scale: CGFloat = 2.0) -> CGImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = scale
        return renderer.cgImage
    }
}
