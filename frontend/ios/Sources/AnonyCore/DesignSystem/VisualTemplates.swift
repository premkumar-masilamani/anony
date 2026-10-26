import SwiftUI

public enum VisualTemplates {

    // MARK: - SanctuaryView (Client Zero-Anxiety Template)
    public struct SanctuaryView: View {
        @State private var isConnecting = false
        @State private var sessionReady = false
        private let clientAlias = "SerenePine42"

        public init() {}

        public var body: some View {
            ZStack {
                // Background sanctuary gradient
                ColorPalette.sanctuaryGradient
                    .ignoresSafeArea()

                // Ambient tranquil background aura
                VStack {
                    HStack {
                        Spacer()
                        PulsingAuraView(
                            color: ColorPalette.calmingCyan,
                            diameter: 220,
                            cycleDuration: 4.5,
                            scaleRange: 0.85...1.15
                        )
                        .offset(x: 40, y: -60)
                    }
                    Spacer()
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Top Header & Identity Bar
                        HStack(alignment: .center, spacing: 16) {
                            AvatarCircleView(seed: clientAlias, size: .large, showAura: true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sanctuary Space")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(ColorPalette.textPrimary)

                                Text("Alias: \(clientAlias)")
                                    .font(.subheadline)
                                    .foregroundColor(ColorPalette.calmingCyan)
                            }

                            Spacer()
                        }
                        .padding(.top, 16)

                        // Privacy & Status Badges
                        HStack(spacing: 8) {
                            TagPillView(
                                text: "Zero-PII Protected",
                                systemImage: "checkmark.shield.fill",
                                variant: .sage
                            )
                            TagPillView(
                                text: "End-to-End Encrypted",
                                systemImage: "lock.fill",
                                variant: .cyan
                            )
                            Spacer()
                        }

                        // Main Safe Space Glass Card
                        GlassCard(style: .elevated, cornerRadius: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "waveform.circle.fill")
                                        .font(.title)
                                        .foregroundColor(ColorPalette.sageGreen)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Private Voice Sanctuary")
                                            .font(.headline)
                                            .foregroundColor(ColorPalette.textPrimary)
                                        Text("Audio reflection • No video • Zero logs")
                                            .font(.caption)
                                            .foregroundColor(ColorPalette.textMuted)
                                    }
                                    Spacer()
                                    TagPillView(text: "Live", variant: .sage)
                                }

                                Divider()
                                    .background(ColorPalette.cardBorder)

                                Text("Take a gentle breath before beginning. Your identity, real name, and metadata remain completely confidential and secure.")
                                    .font(.subheadline)
                                    .foregroundColor(ColorPalette.textSecondary)
                                    .lineSpacing(4)

                                AnonyButton(
                                    title: isConnecting ? "Entering Sanctuary..." : "Enter Safe Session",
                                    systemImage: isConnecting ? nil : "sparkles",
                                    variant: .primary,
                                    size: .large,
                                    isLoading: isConnecting
                                ) {
                                    isConnecting = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        isConnecting = false
                                        sessionReady = true
                                    }
                                }
                            }
                        }

                        // Supporting Guidance Glass Card
                        GlassCard(style: .standard, cornerRadius: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Emotional Grounding Principles")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(ColorPalette.textPrimary)

                                HStack(spacing: 8) {
                                    TagPillView(text: "Respectful Silence", variant: .lavender)
                                    TagPillView(text: "Anonymous Alias", variant: .neutral)
                                    TagPillView(text: "Self-Paced", variant: .cyan)
                                }

                                Text("You are free to leave at any moment. Conversations are transient and never recorded.")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textMuted)
                            }
                        }

                        AnonyButton(
                            title: "Sanctuary Guidelines",
                            systemImage: "doc.text.fill",
                            variant: .ghost,
                            size: .medium
                        ) {
                            // Secondary low-pressure action
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - DesignSystemGalleryView (Interactive Showcase)
    public struct DesignSystemGalleryView: View {
        @State private var sampleLoading = false
        @State private var selectedAuraColor = ColorPalette.sageGreen

        public init() {}

        public var body: some View {
            ZStack {
                ColorPalette.midnightSlate
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SwiftUI Design System")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(ColorPalette.textPrimary)
                            Text("Tranquil theme, zero-anxiety UI & procedural avatars")
                                .font(.subheadline)
                                .foregroundColor(ColorPalette.textMuted)
                        }
                        .padding(.top, 16)

                        // 1. Color Palette Swatches
                        sectionHeader("Tranquil Theme Palette")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            colorSwatch("Midnight Slate", hex: "#0B0F19", color: ColorPalette.midnightSlate)
                            colorSwatch("Warm Charcoal", hex: "#161B26", color: ColorPalette.warmCharcoal)
                            colorSwatch("Elevated Card", hex: "#1E2536", color: ColorPalette.elevatedCard)
                            colorSwatch("Sage Green", hex: "#34D399", color: ColorPalette.sageGreen)
                            colorSwatch("Calming Cyan", hex: "#38BDF8", color: ColorPalette.calmingCyan)
                            colorSwatch("Muted Lavender", hex: "#A78BFA", color: ColorPalette.mutedLavender)
                        }

                        // 2. Procedural Zero-PII Avatars
                        sectionHeader("Procedural Avatars (Zero-PII)")
                        Text("Deterministic geometry & harmonious colors derived strictly from pseudonym seeds without external photos or personal identifiers.")
                            .font(.caption)
                            .foregroundColor(ColorPalette.textMuted)

                        HStack(spacing: 16) {
                            avatarShowcase(seed: "TranquilRiver", label: "Seed: River", size: .extraLarge)
                            avatarShowcase(seed: "GentleDawn", label: "Seed: Dawn", size: .large)
                            avatarShowcase(seed: "SilentForest", label: "Seed: Forest", size: .medium)
                            avatarShowcase(seed: "MutedSky", label: "Seed: Sky", size: .small)
                        }

                        // 3. Reusable Button Matrix
                        sectionHeader("AnonyButton Variants & States")
                        VStack(spacing: 12) {
                            AnonyButton(
                                title: "Primary Button (Large)",
                                systemImage: "sparkles",
                                variant: .primary,
                                size: .large
                            ) {}

                            HStack(spacing: 12) {
                                AnonyButton(
                                    title: "Secondary",
                                    systemImage: "lock.shield",
                                    variant: .secondary,
                                    size: .medium
                                ) {}

                                AnonyButton(
                                    title: "Ghost Action",
                                    systemImage: "info.circle",
                                    variant: .ghost,
                                    size: .medium
                                ) {}
                            }

                            HStack(spacing: 12) {
                                AnonyButton(
                                    title: "Loading State",
                                    variant: .primary,
                                    size: .small,
                                    isLoading: true
                                ) {}

                                AnonyButton(
                                    title: "Disabled State",
                                    variant: .primary,
                                    size: .small,
                                    isDisabled: true
                                ) {}
                            }
                        }

                        // 4. Glass Cards
                        sectionHeader("GlassCard Styles")
                        VStack(spacing: 12) {
                            GlassCard(style: .standard) {
                                HStack {
                                    Text("Standard Glass Card")
                                        .foregroundColor(ColorPalette.textPrimary)
                                    Spacer()
                                    TagPillView(text: "Standard", variant: .neutral)
                                }
                            }

                            GlassCard(style: .elevated) {
                                HStack {
                                    Text("Elevated Surface Card")
                                        .foregroundColor(ColorPalette.textPrimary)
                                    Spacer()
                                    TagPillView(text: "Elevated", variant: .cyan)
                                }
                            }

                            GlassCard(style: .highlighted(ColorPalette.sageGreen)) {
                                HStack {
                                    Text("Highlighted Accent Card")
                                        .foregroundColor(ColorPalette.textPrimary)
                                    Spacer()
                                    TagPillView(text: "Active", variant: .sage)
                                }
                            }
                        }

                        // 5. Breathing Pulsing Aura
                        sectionHeader("Pulsing Aura (3.5s Breathing Rhythm)")
                        HStack(spacing: 24) {
                            VStack {
                                PulsingAuraView(color: ColorPalette.sageGreen, diameter: 70, cycleDuration: 3.5)
                                Text("Sage Breath")
                                    .font(.caption2)
                                    .foregroundColor(ColorPalette.textMuted)
                            }

                            VStack {
                                PulsingAuraView(color: ColorPalette.calmingCyan, diameter: 70, cycleDuration: 3.5)
                                Text("Cyan Presence")
                                    .font(.caption2)
                                    .foregroundColor(ColorPalette.textMuted)
                            }

                            VStack {
                                PulsingAuraView(color: ColorPalette.mutedLavender, diameter: 70, cycleDuration: 3.5)
                                Text("Lavender Reflection")
                                    .font(.caption2)
                                    .foregroundColor(ColorPalette.textMuted)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        // 6. Tag Pills
                        sectionHeader("TagPillView Variants")
                        HStack(spacing: 8) {
                            TagPillView(text: "Calming Cyan", systemImage: "sparkle", variant: .cyan)
                            TagPillView(text: "Sage Green", systemImage: "leaf.fill", variant: .sage)
                            TagPillView(text: "Lavender", systemImage: "moon.fill", variant: .lavender)
                            TagPillView(text: "Neutral", variant: .neutral)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }

        private func sectionHeader(_ title: String) -> some View {
            Text(title)
                .font(.headline)
                .foregroundColor(ColorPalette.calmingCyan)
                .padding(.top, 8)
        }

        private func colorSwatch(_ name: String, hex: String, color: Color) -> some View {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.textPrimary)
                    Text(hex)
                        .font(.caption2)
                        .foregroundColor(ColorPalette.textMuted)
                }
            }
            .padding(10)
            .background(ColorPalette.elevatedCard)
            .cornerRadius(12)
        }

        private func avatarShowcase(seed: String, label: String, size: AvatarCircleView.Size) -> some View {
            VStack(spacing: 6) {
                AvatarCircleView(seed: seed, size: size, showAura: true)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(ColorPalette.textMuted)
            }
        }
    }
}
