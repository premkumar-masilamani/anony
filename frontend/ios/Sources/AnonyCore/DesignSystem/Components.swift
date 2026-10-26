import SwiftUI

public struct AnonyButton: View {
    public let title: String
    public let action: () -> Void

    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ColorPalette.calmingCyan)
                .cornerRadius(12)
                .shadow(color: ColorPalette.calmingCyan.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

public struct GlassCard<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .background(ColorPalette.elevatedCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

public struct PulsingAuraView: View {
    @State private var isPulsing = false

    public init() {}

    public var body: some View {
        Circle()
            .fill(ColorPalette.sageGreen.opacity(0.3))
            .scaleEffect(isPulsing ? 1.2 : 0.9)
            .opacity(isPulsing ? 0.6 : 0.2)
            .animation(
                Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

public struct TagPillView: View {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(ColorPalette.warmCharcoal)
            .foregroundColor(ColorPalette.calmingCyan)
            .cornerRadius(8)
    }
}
