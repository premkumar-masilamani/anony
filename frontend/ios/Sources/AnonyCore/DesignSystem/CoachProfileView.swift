import SwiftUI

/// Dedicated Coach Profile View & Slot Selector.
/// Allows clients to inspect credentials, bio, philosophy, testimonials, and 1-minute video/voice preview,
/// and select time slots converted dynamically into their local timezone.
public struct CoachProfileView: View {
    public let clientAlias: String
    public let onDismiss: (() -> Void)?
    public let onSessionBooked: ((CoachingSession) -> Void)?

    @StateObject public var viewModel: CoachProfileViewModel

    public var coach: Coach { viewModel.coach }
    public var timeZone: TimeZone { viewModel.timeZone }
    public var coachService: CoachServiceProtocol { viewModel.coachService }
    public var localTimeZoneName: String { viewModel.localTimeZoneName }
    public var localTimeZoneAbbreviation: String { viewModel.localTimeZoneAbbreviation }
    public var calendarDays: [Date] { viewModel.calendarDays }
    public var availableSlotsForSelectedDate: [CoachSlot] { viewModel.availableSlotsForSelectedDate }

    public init(
        coach: Coach,
        coachService: CoachServiceProtocol = MockCoachService.shared,
        clientAlias: String? = nil,
        timeZone: TimeZone = .current,
        viewModel: CoachProfileViewModel? = nil,
        onDismiss: (() -> Void)? = nil,
        onSessionBooked: ((CoachingSession) -> Void)? = nil
    ) {
        self.clientAlias = clientAlias ?? "AnonymousClient"
        self.onDismiss = onDismiss
        self.onSessionBooked = onSessionBooked

        if let vm = viewModel {
            _viewModel = StateObject(wrappedValue: vm)
        } else {
            _viewModel = StateObject(wrappedValue: CoachProfileViewModel(
                coach: coach,
                coachService: coachService,
                timeZone: timeZone
            ))
        }
    }

    public var body: some View {
        ZStack {
            ColorPalette.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar
                navigationBar
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Success Toast if just booked
                        if let booked = viewModel.bookedSessionSuccess {
                            bookingSuccessBanner(booked)
                        }

                        // Header Credentials & Bio
                        headerSection

                        // 1-Minute Video Preview Placeholder
                        videoPreviewSection

                        // Testimonials Carousel
                        testimonialsSection

                        // Timezone Banner & Calendar Slot Selector
                        slotSelectorSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 36)
                }
            }
        }
        .sheet(item: $viewModel.selectedSlotForCheckout) { slot in
            CheckoutModalView(
                coach: viewModel.coach,
                slot: slot,
                clientAlias: clientAlias,
                coachService: viewModel.coachService,
                timeZone: viewModel.timeZone,
                onConfirmed: { session in
                    handleBookingCompleted(session: session, bookedSlot: slot)
                },
                onDismiss: {
                    viewModel.selectedSlotForCheckout = nil
                }
            )
        }
        .task {
            await viewModel.reloadCoachDetails()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Back")
                            .font(.subheadline)
                    }
                    .foregroundStyle(ColorPalette.calmingCyan)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                Task {
                    await viewModel.toggleFavorite()
                }
            } label: {
                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundStyle(viewModel.isFavorite ? ColorPalette.mutedLavender : ColorPalette.textMuted)
                    .padding(8)
                    .background(ColorPalette.elevatedCard)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Section 1: Header Credentials & Bio

    private var headerSection: some View {
        GlassCard(style: .elevated, cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    AvatarCircleView(seed: viewModel.coach.avatarSeed, size: .large, showAura: true)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(viewModel.coach.alias)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(ColorPalette.textPrimary)

                            TagPillView(
                                text: viewModel.coach.icfLevel.badgeTitle,
                                systemImage: "award.fill",
                                variant: .lavender
                            )
                        }

                        Text(viewModel.coach.title)
                            .font(.caption)
                            .foregroundStyle(ColorPalette.textSecondary)

                        HStack(spacing: 6) {
                            TagPillView(
                                text: "Verified Human",
                                systemImage: "checkmark.seal.fill",
                                variant: .sage
                            )

                            TagPillView(
                                text: viewModel.coach.topic.title,
                                systemImage: viewModel.coach.topic.systemImage,
                                variant: .cyan
                            )
                        }
                    }

                    Spacer()
                }

                // Stats & Rate Bar
                HStack(spacing: 12) {
                    // Hourly Rate Badge
                    if viewModel.coach.tier == .free {
                        TagPillView(
                            text: "Free Pro-Bono",
                            systemImage: "sparkles",
                            variant: .sage
                        )
                    } else {
                        TagPillView(
                            text: "$\(viewModel.coach.hourlyRate)/hr",
                            systemImage: "creditcard.fill",
                            variant: .cyan
                        )
                    }

                    // Rating Pill
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.sageGreen)
                        Text(String(format: "%.2f", viewModel.coach.rating))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorPalette.warmCharcoal)
                    .clipShape(Capsule())

                    // Sessions Count
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.calmingCyan)
                        Text("\(viewModel.coach.sessionCount) sessions")
                            .font(.caption)
                            .foregroundStyle(ColorPalette.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorPalette.warmCharcoal)
                    .clipShape(Capsule())

                    Spacer()
                }

                Divider()
                    .background(ColorPalette.cardBorder)

                // Bio
                VStack(alignment: .leading, spacing: 6) {
                    Text("About & Background")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textMuted)

                    Text(viewModel.coach.bio)
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textPrimary)
                        .lineSpacing(3)
                }

                // Philosophy
                VStack(alignment: .leading, spacing: 6) {
                    Text("Coaching Philosophy")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.calmingCyan)

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(.caption)
                            .foregroundStyle(ColorPalette.calmingCyan)

                        Text(viewModel.coach.philosophy)
                            .font(.caption)
                            .italic()
                            .foregroundStyle(ColorPalette.textSecondary)
                            .lineSpacing(2)
                    }
                }
            }
        }
    }

    // MARK: - Section 2: 1-Minute Video Preview Placeholder

    private var videoPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Coaching Chemistry & Style")
                    .font(.headline)
                    .foregroundStyle(ColorPalette.textPrimary)

                Spacer()

                TagPillView(
                    text: viewModel.coach.videoPreviewDuration,
                    systemImage: "video.fill",
                    variant: .cyan
                )
            }

            // 1-Minute Preview Placeholder Card
            GlassCard(style: .elevated, cornerRadius: 16) {
                VStack(spacing: 14) {
                    ZStack {
                        // Ambient tranquil gradient background simulating video player preview frame
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ColorPalette.warmCharcoal,
                                        ColorPalette.midnightSlate,
                                        ColorPalette.elevatedCard
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 160)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorPalette.calmingCyan.opacity(0.2), lineWidth: 1)
                            )

                        // Central Play / Audio Waveform Overlay
                        VStack(spacing: 8) {
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    viewModel.toggleVideoPreview()
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(ColorPalette.calmingCyan.opacity(0.2))
                                        .frame(width: 54, height: 54)

                                    Image(systemName: viewModel.isPlayingVideoPreview ? "pause.fill" : "play.fill")
                                        .font(.title2)
                                        .foregroundStyle(ColorPalette.calmingCyan)
                                        .offset(x: viewModel.isPlayingVideoPreview ? 0 : 2)
                                }
                            }
                            .buttonStyle(.plain)

                            Text(viewModel.isPlayingVideoPreview ? "Playing 1-Min Audio Intro..." : "1-Minute Preview Placeholder")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(viewModel.isPlayingVideoPreview ? ColorPalette.sageGreen : ColorPalette.textSecondary)
                        }

                        // Top Badges Overlay
                        VStack {
                            HStack {
                                TagPillView(
                                    text: "Confidential 1-on-1 Preview",
                                    systemImage: "waveform",
                                    variant: .sage
                                )

                                Spacer()

                                Text(viewModel.coach.videoPreviewDuration)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(ColorPalette.textPrimary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .padding(10)

                            Spacer()
                        }
                    }

                    // Explanatory zero-anxiety caption
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.calmingCyan)

                        Text("Get a feel for \(viewModel.coach.alias)'s tone, cadence, and approach before booking.")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Section 3: Testimonials Carousel

    private var testimonialsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Client Testimonials")
                    .font(.headline)
                    .foregroundStyle(ColorPalette.textPrimary)

                Spacer()

                Text("\(viewModel.coach.testimonials.count) verified reviews")
                    .font(.caption2)
                    .foregroundStyle(ColorPalette.textMuted)
            }

            if viewModel.coach.testimonials.isEmpty {
                GlassCard(style: .standard, cornerRadius: 14) {
                    Text("No client testimonials available yet.")
                        .font(.caption)
                        .foregroundStyle(ColorPalette.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.coach.testimonials) { testimonial in
                            testimonialCard(testimonial)
                        }
                    }
                }
            }
        }
    }

    private func testimonialCard(_ testimonial: CoachTestimonial) -> some View {
        GlassCard(style: .elevated, cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    AvatarCircleView(seed: testimonial.clientAlias, size: .small)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(testimonial.clientAlias)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette.textPrimary)

                        Text(testimonial.dateString)
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.textMuted)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.sageGreen)
                        Text(String(format: "%.1f", testimonial.rating))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(ColorPalette.textPrimary)
                    }
                }

                Text("\"\(testimonial.feedback)\"")
                    .font(.caption)
                    .foregroundStyle(ColorPalette.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                TagPillView(
                    text: testimonial.struggleCategory.title,
                    systemImage: testimonial.struggleCategory.systemImage,
                    variant: .cyan
                )
            }
            .frame(width: 250)
        }
    }

    // MARK: - Section 4: Timezone Banner & Slot Selector

    private var slotSelectorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Title
            HStack {
                Text("Select an Available Audio Slot")
                    .font(.headline)
                    .foregroundStyle(ColorPalette.textPrimary)

                Spacer()

                TagPillView(
                    text: "50-Min 1-on-1",
                    variant: .sage
                )
            }

            // Local Timezone Banner (Acceptance Criterion 1)
            GlassCard(style: .standard, cornerRadius: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundStyle(ColorPalette.calmingCyan)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Client Timezone")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.textMuted)

                        Text("\(viewModel.localTimeZoneName) (\(viewModel.localTimeZoneAbbreviation))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette.textPrimary)
                    }

                    Spacer()

                    TagPillView(
                        text: "Local Time",
                        systemImage: "globe",
                        variant: .cyan
                    )
                }
            }

            // Horizontal 7-Day Date Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.calendarDays, id: \.self) { day in
                        calendarDayChip(day)
                    }
                }
            }

            // Slot Chips for Selected Day
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Slots for \(formattedDayTitle(viewModel.selectedDate)):")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textMuted)

                    Spacer()

                    Text("\(viewModel.availableSlotsForSelectedDate.count) available")
                        .font(.caption2)
                        .foregroundStyle(ColorPalette.calmingCyan)
                }

                if viewModel.availableSlotsForSelectedDate.isEmpty {
                    GlassCard(style: .standard, cornerRadius: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .foregroundStyle(ColorPalette.textMuted)
                            Text("No open slots for this day. Please pick another date above.")
                                .font(.caption)
                                .foregroundStyle(ColorPalette.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 14)
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        ForEach(viewModel.availableSlotsForSelectedDate) { slot in
                            slotChip(slot)
                        }
                    }
                }
            }
        }
    }

    private func calendarDayChip(_ date: Date) -> some View {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = viewModel.timeZone
        let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.timeZone = viewModel.timeZone
        weekdayFormatter.locale = Locale(identifier: "en_US_POSIX")
        weekdayFormatter.dateFormat = "EEE"

        let dayFormatter = DateFormatter()
        dayFormatter.timeZone = viewModel.timeZone
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.dateFormat = "d"

        let weekday = weekdayFormatter.string(from: date)
        let dayNumber = dayFormatter.string(from: date)

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.selectedDate = date
            }
        }) {
            VStack(spacing: 4) {
                Text(weekday)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? ColorPalette.midnightSlate : ColorPalette.textMuted)

                Text(dayNumber)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? ColorPalette.midnightSlate : ColorPalette.textPrimary)
            }
            .frame(width: 52, height: 60)
            .background(isSelected ? ColorPalette.calmingCyan : ColorPalette.elevatedCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? ColorPalette.calmingCyan : ColorPalette.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func slotChip(_ slot: CoachSlot) -> some View {
        Button(action: {
            // Tapping slot opens checkout modal (Acceptance Criterion 2)
            viewModel.selectSlot(slot)
        }) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption2)

                Text(slot.formattedTime(in: viewModel.timeZone))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(ColorPalette.elevatedCard)
            .foregroundStyle(ColorPalette.calmingCyan)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(ColorPalette.calmingCyan.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func formattedDayTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = viewModel.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private func bookingSuccessBanner(_ session: CoachingSession) -> some View {
        GlassCard(style: .highlighted(ColorPalette.sageGreen), cornerRadius: 14) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(ColorPalette.sageGreen)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Session Reserved Successfully!")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("\(session.timeSlot) (\(session.timeZoneIdentifier)) with \(session.coachAlias)")
                        .font(.caption)
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Actions

    public func handleBookingCompleted(session: CoachingSession, bookedSlot: CoachSlot) {
        viewModel.selectedSlotForCheckout = nil
        viewModel.bookedSessionSuccess = session

        // Update local coach slot state
        if let idx = viewModel.coach.slots.firstIndex(where: { $0.id == bookedSlot.id }) {
            var updatedSlots = viewModel.coach.slots
            updatedSlots[idx].isBooked = true

            viewModel.coach = Coach(
                id: viewModel.coach.id,
                alias: viewModel.coach.alias,
                title: viewModel.coach.title,
                specialty: viewModel.coach.specialty,
                topic: viewModel.coach.topic,
                tier: viewModel.coach.tier,
                icfLevel: viewModel.coach.icfLevel,
                languages: viewModel.coach.languages,
                hourlyRate: viewModel.coach.hourlyRate,
                rating: viewModel.coach.rating,
                sessionCount: viewModel.coach.sessionCount + 1,
                avatarSeed: viewModel.coach.avatarSeed,
                availableSlots: viewModel.coach.availableSlots,
                bio: viewModel.coach.bio,
                philosophy: viewModel.coach.philosophy,
                photoURL: viewModel.coach.photoURL,
                videoPreviewTitle: viewModel.coach.videoPreviewTitle,
                videoPreviewDuration: viewModel.coach.videoPreviewDuration,
                testimonials: viewModel.coach.testimonials,
                slots: updatedSlots
            )
        }

        onSessionBooked?(session)
    }
}
