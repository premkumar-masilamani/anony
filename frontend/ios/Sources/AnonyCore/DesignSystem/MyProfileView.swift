import SwiftUI

/// Profile & Settings view allowing clients to toggle anonymity mode and update personal information.
public struct MyProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    public let onDismiss: (() -> Void)?

    public init(
        profileService: ProfileServiceProtocol = UserDefaultsProfileService.shared,
        onProfileUpdated: ((ClientProfile) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(
            profileService: profileService,
            onProfileUpdated: onProfileUpdated
        ))
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            ColorPalette.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Top Navigation Header
                    navigationHeader

                    // Identity & Procedural Avatar Card
                    identityCard

                    // Privacy & Anonymity Mode Toggle Section
                    anonymityModeSection

                    // Personal Information Form
                    personalInformationSection

                    // Save Action Button & Status Feedback
                    saveSection

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Subviews

    private var navigationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(ColorPalette.textPrimary)

                Text("Identity privacy, personal details, and matching preferences")
                    .font(.caption)
                    .foregroundStyle(ColorPalette.textMuted)
            }

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(ColorPalette.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var identityCard: some View {
        GlassCard(style: .elevated, cornerRadius: 20) {
            HStack(spacing: 16) {
                AvatarCircleView(seed: viewModel.alias, size: .large, showAura: true)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(viewModel.alias.isEmpty ? "Anonymous Client" : viewModel.alias)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(ColorPalette.textPrimary)

                        Button {
                            viewModel.regenerateAlias()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption)
                                .foregroundStyle(ColorPalette.calmingCyan)
                                .padding(6)
                                .background(ColorPalette.warmCharcoal)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Generate new tranquil pseudonym")
                    }

                    if viewModel.isAnonymousMode {
                        TagPillView(
                            text: "Anonymous Blind Mode",
                            systemImage: "eye.slash.fill",
                            variant: .cyan
                        )
                    } else {
                        TagPillView(
                            text: "Regular Directory Mode",
                            systemImage: "person.fill.checkmark",
                            variant: .lavender
                        )
                    }

                    if !viewModel.fullName.isEmpty {
                        Text(viewModel.fullName)
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.textSecondary)
                    }
                }

                Spacer()
            }
        }
    }

    private var anonymityModeSection: some View {
        GlassCard(style: .standard, cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isAnonymousMode ? "shield.lefthalf.filled" : "person.text.rectangle")
                            .font(.headline)
                            .foregroundStyle(viewModel.isAnonymousMode ? ColorPalette.calmingCyan : ColorPalette.mutedLavender)

                        Text("Anonymity & Matching Mode")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette.textPrimary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { viewModel.isAnonymousMode },
                        set: { _ in
                            Task {
                                await viewModel.toggleAnonymity()
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(ColorPalette.calmingCyan)
                }

                Divider()
                    .background(ColorPalette.cardBorder)

                // Explanatory Mode Narrative
                if viewModel.isAnonymousMode {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Anonymous Blind Mode Active")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette.calmingCyan)

                        Text("You are automatically paired blind with verified pro-bono coaches based on your struggle prompt. Direct coach directory browsing is hidden to eliminate choice anxiety and preserve complete impartiality.")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.textSecondary)
                            .lineSpacing(3)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Regular Directory Mode Active")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette.mutedLavender)

                        Text("You have full agency to browse the coach directory, filter by ICF credentials, specialty topics, hourly rates, and select preferred coaches directly.")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.textSecondary)
                            .lineSpacing(3)
                    }
                }

                // Free Pro-Bono Quota Meter
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pro-Bono Session Quota:")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette.textMuted)

                        Spacer()

                        Text("\(viewModel.freeSessionsUsed) of \(viewModel.maxFreeSessions) used")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(ColorPalette.sageGreen)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ColorPalette.warmCharcoal)
                                .frame(height: 6)

                            Capsule()
                                .fill(ColorPalette.sageGreen)
                                .frame(width: geo.size.width * CGFloat(viewModel.freeSessionsUsed) / CGFloat(viewModel.maxFreeSessions), height: 6)
                        }
                    }
                    .frame(height: 6)

                    if viewModel.isCooldownActive {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.caption2)
                            Text("Next free session unlocks in \(viewModel.daysUntilNextFreeSession) days.")
                                .font(.caption2)
                        }
                        .foregroundStyle(ColorPalette.textMuted)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var personalInformationSection: some View {
        GlassCard(style: .standard, cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.square.fill")
                        .font(.headline)
                        .foregroundStyle(ColorPalette.calmingCyan)

                    Text("Personal Information")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.textPrimary)
                }

                // 1. Alias Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Anonymous Alias (Visible to Coaches)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(ColorPalette.textMuted)

                    HStack(spacing: 8) {
                        TextField("e.g. TranquilRiver42", text: $viewModel.alias)
                            .textFieldStyle(.plain)
                            .font(.caption)
                            .foregroundStyle(ColorPalette.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(ColorPalette.warmCharcoal)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(ColorPalette.cardBorder, lineWidth: 1)
                            )

                        AnonyButton(
                            title: "Random",
                            systemImage: "sparkles",
                            variant: .ghost,
                            size: .small
                        ) {
                            viewModel.regenerateAlias()
                        }
                    }
                }

                // 2. Full Name Field
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Full / Display Name")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(ColorPalette.textMuted)

                        Spacer()

                        Text("Zero-PII Protected")
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.sageGreen)
                    }

                    TextField("Optional display name", text: $viewModel.fullName)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(ColorPalette.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(ColorPalette.warmCharcoal)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ColorPalette.cardBorder, lineWidth: 1)
                        )

                    Text("Kept strictly confidential and never shared with coaches during anonymous sessions.")
                        .font(.caption2)
                        .foregroundStyle(ColorPalette.textMuted)
                }

                // 3. Email Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email Address")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(ColorPalette.textMuted)

                    TextField("name@example.com", text: $viewModel.email)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(ColorPalette.textPrimary)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(ColorPalette.warmCharcoal)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ColorPalette.cardBorder, lineWidth: 1)
                        )
                }

                // 4. Primary Focus Area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Growth Focus")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(ColorPalette.textMuted)

                    HStack(spacing: 8) {
                        ForEach(StruggleCategory.allCases) { category in
                            let isSelected = viewModel.primaryFocus == category
                            Button {
                                viewModel.primaryFocus = category
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: category.systemImage)
                                        .font(.caption2)
                                    Text(category.title.components(separatedBy: " ").first ?? category.title)
                                        .font(.caption2)
                                        .fontWeight(isSelected ? .semibold : .regular)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isSelected ? ColorPalette.calmingCyan.opacity(0.2) : ColorPalette.warmCharcoal)
                                .foregroundStyle(isSelected ? ColorPalette.calmingCyan : ColorPalette.textSecondary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? ColorPalette.calmingCyan : ColorPalette.cardBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // 5. Preferred Language
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred Session Language")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(ColorPalette.textMuted)

                    let languages = ["English", "Spanish", "French", "German", "Mandarin"]
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(languages, id: \.self) { lang in
                                let isSelected = viewModel.preferredLanguage == lang
                                Button {
                                    viewModel.preferredLanguage = lang
                                } label: {
                                    Text(lang)
                                        .font(.caption2)
                                        .fontWeight(isSelected ? .semibold : .regular)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? ColorPalette.sageGreen.opacity(0.2) : ColorPalette.warmCharcoal)
                                        .foregroundStyle(isSelected ? ColorPalette.sageGreen : ColorPalette.textSecondary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(isSelected ? ColorPalette.sageGreen : ColorPalette.cardBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var saveSection: some View {
        VStack(spacing: 12) {
            if let success = viewModel.saveSuccessMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ColorPalette.sageGreen)
                    Text(success)
                        .font(.caption)
                        .foregroundStyle(ColorPalette.sageGreen)
                }
                .transition(.opacity)
            }

            if let error = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(ColorPalette.mutedLavender)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(ColorPalette.mutedLavender)
                }
                .transition(.opacity)
            }

            AnonyButton(
                title: viewModel.isSaving ? "Saving Changes..." : "Save Profile Changes",
                systemImage: viewModel.isSaving ? nil : "checkmark",
                variant: .primary,
                size: .large,
                isLoading: viewModel.isSaving
            ) {
                Task {
                    await viewModel.saveProfile()
                }
            }
        }
    }
}
