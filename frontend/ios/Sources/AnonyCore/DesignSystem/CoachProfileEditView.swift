import SwiftUI

/// Sheet view allowing a coach to edit their profile and resubmit ICF credentials for verification.
public struct CoachProfileEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String
    @State private var lastName: String
    @State private var photoUrl: String
    @State private var selectedCountryName: String
    @State private var countryCode: String
    @State private var timezone: String
    @State private var gender: String

    @State private var icfAcc: Bool
    @State private var icfPcc: Bool
    @State private var icfMcc: Bool
    @State private var icfActc: Bool

    @State private var credentialDetails: String
    @State private var biography: String
    @State private var hourlyRateText: String
    @State private var selectedDomains: Set<String>
    @State private var customDomainText: String = ""

    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    private let authService: AuthServiceProtocol
    private let onSaved: (CoachProfileResponse) -> Void

    public init(
        profile: CoachProfileResponse,
        authService: AuthServiceProtocol = RemoteAuthService(),
        onSaved: @escaping (CoachProfileResponse) -> Void
    ) {
        self._firstName = State(initialValue: profile.firstName)
        self._lastName = State(initialValue: profile.lastName)
        self._photoUrl = State(initialValue: profile.photoUrl ?? "")
        let resolvedIso = profile.countryCode ?? "US"
        let resolvedCountry = CountryTimezoneConfig.countryName(forIsoCode: resolvedIso)
        self._selectedCountryName = State(initialValue: resolvedCountry)
        self._countryCode = State(initialValue: resolvedIso)

        let tzs = CountryTimezoneConfig.timezones(forCountry: resolvedCountry)
        let resolvedTz = tzs.first(where: { $0.value == profile.timezone })?.value ?? (tzs.first?.value ?? profile.timezone)
        self._timezone = State(initialValue: resolvedTz)
        self._gender = State(initialValue: profile.gender ?? "")

        self._icfAcc = State(initialValue: profile.icfAcc)
        self._icfPcc = State(initialValue: profile.icfPcc)
        self._icfMcc = State(initialValue: profile.icfMcc)
        self._icfActc = State(initialValue: profile.icfActc)

        // Clean out formatted hourly rate string from credential details for cleaner editing
        let rawDetails = profile.credentialDetails ?? ""
        let cleanedDetails: String
        if let markerRange = rawDetails.range(of: " | Hourly Rate: $") {
            cleanedDetails = String(rawDetails[..<markerRange.lowerBound])
        } else if rawDetails.starts(with: "Hourly Rate: $") {
            cleanedDetails = ""
        } else {
            cleanedDetails = rawDetails
        }
        self._credentialDetails = State(initialValue: cleanedDetails)

        self._biography = State(initialValue: profile.biography ?? "")

        let initialRate = profile.hourlyRate ?? 150.0
        self._hourlyRateText = State(initialValue: String(Int(initialRate)))

        let domainSet = profile.domainCodes.isEmpty ? ["CAREER"] : Set(profile.domainCodes)
        self._selectedDomains = State(initialValue: domainSet)

        self.authService = authService
        self.onSaved = onSaved
    }

    private var hasAtLeastOneCertification: Bool {
        icfAcc || icfPcc || icfMcc || icfActc
    }

    private var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
            && hasAtLeastOneCertification
            && !selectedDomains.isEmpty
            && !isSaving
    }

    private func selectCountry(_ name: String) {
        selectedCountryName = name
        countryCode = CountryTimezoneConfig.isoCode(forCountry: name)
        let tzs = CountryTimezoneConfig.timezones(forCountry: name)
        if let firstTz = tzs.first {
            timezone = firstTz.value
        }
    }

    private func addCustomDomain() {
        let trimmed = customDomainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let normalized = CoachingDomainConfig.normalizeCode(from: trimmed)
        selectedDomains.insert(normalized)
        customDomainText = ""
    }

    public var body: some View {
        ZStack {
            ColorPalette.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Profile")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(ColorPalette.textPrimary)
                            Text("Update your details and resubmit for verification review.")
                                .font(.caption)
                                .foregroundColor(ColorPalette.textSecondary)
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(ColorPalette.textMuted)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    GlassCard(style: .elevated, cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 18) {
                            // First Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("First Name")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)
                                TextField("First name", text: $firstName)
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .foregroundColor(ColorPalette.textPrimary)
                            }

                            // Last Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Last Name")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)
                                TextField("Last name", text: $lastName)
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .foregroundColor(ColorPalette.textPrimary)
                            }

                            // Photo URL
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Profile Photo URL (Optional)")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)
                                TextField("https://example.com/photo.jpg", text: $photoUrl)
                                    .autocorrectionDisabled()
                                    #if os(iOS)
                                    .textInputAutocapitalization(.never)
                                    #endif
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .foregroundColor(ColorPalette.textPrimary)
                            }

                            // Country Dropdown (Human-readable)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Country")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                Menu {
                                    ForEach(CountryTimezoneConfig.allCountries) { country in
                                        Button {
                                            selectCountry(country.name)
                                        } label: {
                                            if country.name == selectedCountryName {
                                                Label(country.name, systemImage: "checkmark")
                                            } else {
                                                Text(country.name)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCountryName)
                                            .font(.subheadline)
                                            .foregroundColor(ColorPalette.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(ColorPalette.textSecondary)
                                    }
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(ColorPalette.cardBorder, lineWidth: 1)
                                    )
                                }
                                .accessibilityIdentifier("CountryDropdown")
                            }

                            // Timezone Dropdown (Auto-populated from selected country)
                            VStack(alignment: .leading, spacing: 6) {
                                let tzs = CountryTimezoneConfig.timezones(forCountry: selectedCountryName)
                                let selectedLabel = tzs.first(where: { $0.value == timezone })?.label ?? timezone

                                HStack {
                                    Text("Timezone")
                                        .font(.caption)
                                        .foregroundColor(ColorPalette.textSecondary)
                                    if tzs.count > 1 {
                                        Text("(\(tzs.count) available)")
                                            .font(.caption2)
                                            .foregroundColor(ColorPalette.calmingCyan)
                                    }
                                }

                                Menu {
                                    ForEach(tzs) { tzOption in
                                        Button {
                                            timezone = tzOption.value
                                        } label: {
                                            if tzOption.value == timezone {
                                                Label(tzOption.label, systemImage: "checkmark")
                                            } else {
                                                Text(tzOption.label)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedLabel)
                                            .font(.subheadline)
                                            .foregroundColor(ColorPalette.textPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(ColorPalette.textSecondary)
                                    }
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(ColorPalette.cardBorder, lineWidth: 1)
                                    )
                                }
                                .accessibilityIdentifier("TimezoneDropdown")
                            }

                            // Gender
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Gender (Optional)")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)
                                HStack(spacing: 6) {
                                    genderButton(id: "MALE", label: "Male")
                                    genderButton(id: "FEMALE", label: "Female")
                                    genderButton(id: "NON_BINARY", label: "Non-Binary")
                                    genderButton(id: "PREFER_NOT_TO_SAY", label: "Prefer not")
                                }
                            }

                            Divider()
                                .background(ColorPalette.cardBorder)
                                .padding(.vertical, 4)

                            // ICF Checkboxes
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ICF Credentials (Check all that apply)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(ColorPalette.calmingCyan)
                            }

                            VStack(spacing: 8) {
                                editCheckbox(isChecked: $icfAcc, acronym: "ACC", title: "Associate Certified Coach")
                                editCheckbox(isChecked: $icfPcc, acronym: "PCC", title: "Professional Certified Coach")
                                editCheckbox(isChecked: $icfMcc, acronym: "MCC", title: "Master Certified Coach")
                                editCheckbox(isChecked: $icfActc, acronym: "ACTC", title: "Advanced Certification in Team Coaching")
                            }

                            // Credential Details Text Editor
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Credential Details & Certificate Identifiers")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                ZStack(alignment: .topLeading) {
                                    if credentialDetails.isEmpty {
                                        Text("Enter ICF credential IDs, dates of issuance, certifying chapters, or training details...")
                                            .font(.caption)
                                            .foregroundColor(ColorPalette.textMuted)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 10)
                                    }
                                    TextEditor(text: $credentialDetails)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .foregroundColor(ColorPalette.textPrimary)
                                        .font(.subheadline)
                                        .padding(6)
                                }
                                .frame(minHeight: 85)
                                .background(ColorPalette.warmCharcoal)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(ColorPalette.cardBorder, lineWidth: 1)
                                )
                            }

                            // Bio Text Editor
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Biography & Coaching Philosophy")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                ZStack(alignment: .topLeading) {
                                    if biography.isEmpty {
                                        Text("Share your background, coaching approach, and client focus areas...")
                                            .font(.caption)
                                            .foregroundColor(ColorPalette.textMuted)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 10)
                                    }
                                    TextEditor(text: $biography)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .foregroundColor(ColorPalette.textPrimary)
                                        .font(.subheadline)
                                        .padding(6)
                                }
                                .frame(minHeight: 90)
                                .background(ColorPalette.warmCharcoal)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(ColorPalette.cardBorder, lineWidth: 1)
                                )
                            }

                            // Hourly Rate
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Hourly Rate ($ USD)")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)
                                TextField("150", text: $hourlyRateText)
                                    #if os(iOS)
                                    .keyboardType(.numberPad)
                                    #endif
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .foregroundColor(ColorPalette.textPrimary)
                            }

                            // Domain Selection & Custom Domains
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Coaching Domains")
                                        .font(.caption)
                                        .foregroundColor(ColorPalette.textSecondary)
                                    Spacer()
                                    Text("(\(selectedDomains.count) selected)")
                                        .font(.caption2)
                                        .foregroundColor(ColorPalette.calmingCyan)
                                }

                                // Selected Domains Chips (Wrapped & Fully Visible)
                                if !selectedDomains.isEmpty {
                                    FlowLayout(spacing: 8) {
                                        ForEach(Array(selectedDomains).sorted(), id: \.self) { domain in
                                            HStack(spacing: 6) {
                                                Text(CoachingDomainConfig.label(forCode: domain))
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(ColorPalette.calmingCyan)
                                                    .lineLimit(1)
                                                    .fixedSize(horizontal: true, vertical: false)

                                                Button {
                                                    if selectedDomains.count > 1 {
                                                        selectedDomains.remove(domain)
                                                    }
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(ColorPalette.calmingCyan.opacity(0.7))
                                                }
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(ColorPalette.calmingCyan.opacity(0.12))
                                            .cornerRadius(14)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(ColorPalette.calmingCyan.opacity(0.35), lineWidth: 1)
                                            )
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }

                                // Dropdown Menu to add standard domains
                                Menu {
                                    ForEach(CoachingDomainConfig.standardDomains) { option in
                                        Button {
                                            if selectedDomains.contains(option.code) {
                                                if selectedDomains.count > 1 {
                                                    selectedDomains.remove(option.code)
                                                }
                                            } else {
                                                selectedDomains.insert(option.code)
                                            }
                                        } label: {
                                            if selectedDomains.contains(option.code) {
                                                Label(option.label, systemImage: "checkmark")
                                            } else {
                                                Text(option.label)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(ColorPalette.calmingCyan)
                                        Text("Select domain from dropdown...")
                                            .font(.subheadline)
                                            .foregroundColor(ColorPalette.textSecondary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(ColorPalette.textMuted)
                                    }
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(ColorPalette.cardBorder, lineWidth: 1)
                                    )
                                }
                                .accessibilityIdentifier("DomainDropdown")

                                // Custom Domain Input
                                HStack(spacing: 8) {
                                    TextField("Add custom domain (e.g. Executive Presence)", text: $customDomainText)
                                        .padding(10)
                                        .background(ColorPalette.warmCharcoal)
                                        .cornerRadius(8)
                                        .foregroundColor(ColorPalette.textPrimary)
                                        .onSubmit {
                                            addCustomDomain()
                                        }

                                    Button(action: addCustomDomain) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                            Text("Add")
                                        }
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(ColorPalette.calmingCyan)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(ColorPalette.calmingCyan.opacity(0.15))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(ColorPalette.calmingCyan.opacity(0.4), lineWidth: 1)
                                        )
                                    }
                                    .disabled(customDomainText.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                            }

                            if let error = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(ColorPalette.mutedLavender)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(ColorPalette.mutedLavender)
                                }
                            }

                            AnonyButton(
                                title: "Submit",
                                systemImage: "checkmark.seal.fill",
                                variant: .primary,
                                size: .large,
                                isLoading: isSaving,
                                isDisabled: !canSave
                            ) {
                                saveUpdates()
                            }
                            .padding(.top, 8)
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func genderButton(id: String, label: String) -> some View {
        let isSelected = (gender == id)
        return Button {
            gender = isSelected ? "" : id
        } label: {
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? ColorPalette.textPrimary : ColorPalette.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSelected ? ColorPalette.calmingCyan.opacity(0.25) : ColorPalette.warmCharcoal)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? ColorPalette.calmingCyan : ColorPalette.cardBorder, lineWidth: 1)
                )
        }
    }

    private func editCheckbox(isChecked: Binding<Bool>, acronym: String, title: String) -> some View {
        Button {
            isChecked.wrappedValue.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked.wrappedValue ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked.wrappedValue ? ColorPalette.sageGreen : ColorPalette.textMuted)
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text(acronym)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.textPrimary)
                    Text(title)
                        .font(.caption2)
                        .foregroundColor(ColorPalette.textSecondary)
                }
                Spacer()
            }
            .padding(10)
            .background(isChecked.wrappedValue ? ColorPalette.sageGreen.opacity(0.12) : ColorPalette.warmCharcoal)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isChecked.wrappedValue ? ColorPalette.sageGreen : ColorPalette.cardBorder, lineWidth: 1)
            )
        }
    }

    private func saveUpdates() {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil

        let rate = Double(hourlyRateText) ?? 150.0
        let primaryLevel = icfMcc ? "MCC" : (icfPcc ? "PCC" : (icfActc ? "ACTC" : "ACC"))

        let payload = CoachUpdatePayload(
            firstName: firstName,
            lastName: lastName,
            photoUrl: photoUrl.isEmpty ? nil : photoUrl,
            gender: gender.isEmpty ? nil : gender,
            countryCode: countryCode.isEmpty ? nil : countryCode.uppercased(),
            timezone: timezone.isEmpty ? TimeZone.current.identifier : timezone,
            biography: biography.isEmpty ? nil : biography,
            icfLevel: primaryLevel,
            icfAcc: icfAcc,
            icfPcc: icfPcc,
            icfMcc: icfMcc,
            icfActc: icfActc,
            credentialDetails: credentialDetails.isEmpty ? nil : credentialDetails,
            domainCodes: Array(selectedDomains),
            hourlyRate: rate
        )

        Task { @MainActor in
            do {
                let updated = try await authService.updateCoachProfile(payload: payload)
                isSaving = false
                onSaved(updated)
                dismiss()
            } catch let error as AuthError {
                isSaving = false
                errorMessage = error.localizedDescription
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
