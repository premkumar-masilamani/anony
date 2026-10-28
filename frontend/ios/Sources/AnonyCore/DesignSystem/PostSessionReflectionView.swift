import SwiftUI

/// Tranquil star rating selector with interactive zero-anxiety feedback.
public struct StarRatingView: View {
    @Binding public var rating: Int
    public let maxRating: Int
    public let activeColor: Color
    public let inactiveColor: Color
    public let starSize: CGFloat

    public init(
        rating: Binding<Int>,
        maxRating: Int = 5,
        activeColor: Color = ColorPalette.sageGreen,
        inactiveColor: Color = ColorPalette.textMuted.opacity(0.35),
        starSize: CGFloat = 28
    ) {
        self._rating = rating
        self.maxRating = maxRating
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.starSize = starSize
    }

    public var body: some View {
        HStack(spacing: 12) {
            ForEach(1...maxRating, id: \.self) { star in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        rating = star
                    }
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: starSize))
                        .foregroundStyle(star <= rating ? activeColor : inactiveColor)
                        .scaleEffect(star <= rating ? 1.08 : 1.0)
                        .shadow(
                            color: star <= rating ? activeColor.opacity(0.3) : Color.clear,
                            radius: 6,
                            x: 0,
                            y: 2
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(star) of \(maxRating) stars")
            }
        }
    }
}

/// Post-session reflection modal sheet facilitating single-tap ratings (1 to 5),
/// public anonymous testimonials, and strictly private personal reflection notes.
public struct PostSessionReflectionView: View {
    public let session: CoachingSession
    public let onSave: (SessionReflection) -> Void
    public let onDismiss: () -> Void

    @State private var rating: Int = 5
    @State private var selectedTags: Set<String> = ["Calm"]
    @State private var publicTestimonial: String = ""
    @State private var privateReflectionNote: String = ""
    @State private var isSubmitting: Bool = false

    public init(
        session: CoachingSession,
        initialRating: Int = 5,
        onSave: @escaping (SessionReflection) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.session = session
        self._rating = State(initialValue: initialRating)
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                ColorPalette.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Card
                        headerCard

                        // 1 to 5 Star Rating Section
                        ratingCard

                        // Quick Reflection Tag Pills
                        quickTagsSection

                        // Public Testimonial
                        publicTestimonialCard

                        // Private Personal Reflection Note (Client Only)
                        privateReflectionCard

                        // Action Buttons
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                    }
                    .foregroundStyle(ColorPalette.textSecondary)
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        VStack(spacing: 8) {
            ZStack {
                PulsingAuraView(color: ColorPalette.calmingCyan, diameter: 64, cycleDuration: 3.5)
                AvatarCircleView(seed: session.coachAvatarSeed, size: .large)
            }

            Text("Session Completed")
                .font(.headline)
                .foregroundStyle(ColorPalette.textSecondary)

            Text("Reflect on your time with \(session.coachAlias)")
                .font(.title3.weight(.bold))
                .foregroundStyle(ColorPalette.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    private var ratingCard: some View {
        GlassCard(style: .elevated, cornerRadius: 16) {
            VStack(spacing: 14) {
                Text("How supported did you feel?")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(ColorPalette.textSecondary)

                StarRatingView(rating: $rating)

                Text(ratingDescription(for: rating))
                    .font(.caption)
                    .foregroundStyle(ColorPalette.calmingCyan)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var quickTagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Reflections")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ColorPalette.textSecondary)

            FlowLayout(spacing: 8) {
                ForEach(SessionReflection.availableQuickTags, id: \.self) { tag in
                    let isSelected = selectedTags.contains(tag)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            if isSelected {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    } label: {
                        TagPillView(
                            text: tag,
                            systemImage: isSelected ? "checkmark" : nil,
                            variant: isSelected ? .cyan : .neutral
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var publicTestimonialCard: some View {
        GlassCard(style: .elevated, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Public Testimonial")
                        .font(.headline)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Spacer()

                    TagPillView(
                        text: "Zero PII • Coach Profile",
                        systemImage: "eye.fill",
                        variant: .cyan
                    )
                }

                Text("Share anonymous gratitude to help others find guidance.")
                    .font(.caption2)
                    .foregroundStyle(ColorPalette.textMuted)

                TextField("What was most helpful about this session?", text: $publicTestimonial, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(ColorPalette.warmCharcoal)
                    .cornerRadius(10)
                    .foregroundStyle(ColorPalette.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(ColorPalette.cardBorder, lineWidth: 1)
                    )
            }
        }
    }

    private var privateReflectionCard: some View {
        GlassCard(style: .highlighted(ColorPalette.mutedLavender), cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Personal Reflection Note", systemImage: "lock.fill")
                        .font(.headline)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Spacer()

                    TagPillView(
                        text: "Private to Client Only",
                        systemImage: "lock.shield.fill",
                        variant: .lavender
                    )
                }

                Text("Saved strictly on your device. Never shared with your coach, platform, or anyone else.")
                    .font(.caption2)
                    .foregroundStyle(ColorPalette.mutedLavender)

                TextField("Write personal insights or gentle reminders for yourself...", text: $privateReflectionNote, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(ColorPalette.warmCharcoal)
                    .cornerRadius(10)
                    .foregroundStyle(ColorPalette.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(ColorPalette.mutedLavender.opacity(0.35), lineWidth: 1)
                    )
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            AnonyButton(
                title: "Save Reflection",
                systemImage: "checkmark.circle.fill",
                variant: .primary,
                size: .large,
                isLoading: isSubmitting
            ) {
                submitReflection()
            }

            AnonyButton(
                title: "Skip for Now",
                variant: .ghost,
                size: .medium
            ) {
                onDismiss()
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func submitReflection() {
        guard !isSubmitting else { return }
        isSubmitting = true

        let reflection = SessionReflection(
            sessionId: session.id,
            coachAlias: session.coachAlias,
            rating: rating,
            publicTestimonial: publicTestimonial.isEmpty ? nil : publicTestimonial,
            privateReflectionNote: privateReflectionNote.isEmpty ? nil : privateReflectionNote,
            quickTags: Array(selectedTags),
            createdAt: Date()
        )

        onSave(reflection)
    }

    private func ratingDescription(for value: Int) -> String {
        switch value {
        case 5: return "5 of 5 • Exceptionally Grounded & Supported"
        case 4: return "4 of 5 • Very Helpful & Calming"
        case 3: return "3 of 5 • Helpful Support"
        case 2: return "2 of 5 • Mildly Supported"
        default: return "1 of 5 • Room for Deeper Connection"
        }
    }
}
