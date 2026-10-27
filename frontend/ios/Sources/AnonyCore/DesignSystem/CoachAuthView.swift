import SwiftUI

/// View facilitating coach registration and ICF credential submission (Issue #17).
public struct CoachAuthView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var photoUrl: String = ""
    @State private var countryCode: String = "US"
    @State private var timezone: String = TimeZone.current.identifier
    @State private var gender: String = ""

    // ICF Credential Checkboxes (can select multiple)
    @State private var icfAcc: Bool = true
    @State private var icfPcc: Bool = false
    @State private var icfMcc: Bool = false
    @State private var icfActc: Bool = false

    @State private var credentialDetails: String = ""
    @State private var biography: String = ""
    @State private var hourlyRateText: String = "150"
    @State private var selectedDomains: Set<String> = ["CAREER", "LEADERSHIP"]

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    private let availableDomains = [
        ("CAREER", "Career"),
        ("LEADERSHIP", "Leadership"),
        ("BURNOUT", "Burnout"),
        ("WORK_LIFE_BALANCE", "Work-Life"),
        ("CONFIDENCE", "Confidence"),
        ("MINDSET", "Mindset"),
        ("COMMUNICATION", "Communication"),
        ("PURPOSE", "Purpose")
    ]

    private let authService: AuthServiceProtocol
    private let onSwitchToClient: () -> Void
    private let onSuccess: (AuthSession) -> Void

    public init(
        authService: AuthServiceProtocol = RemoteAuthService(),
        onSwitchToClient: @escaping () -> Void,
        onSuccess: @escaping (AuthSession) -> Void
    ) {
        self.authService = authService
        self.onSwitchToClient = onSwitchToClient
        self.onSuccess = onSuccess
    }

    private var hasAtLeastOneCertification: Bool {
        icfAcc || icfPcc || icfMcc || icfActc
    }

    private var isEmailValid: Bool {
        RegistrationValidator.isValidEmail(email)
    }

    private var isPasswordValid: Bool {
        RegistrationValidator.isValidPassword(password)
    }

    private var canSubmit: Bool {
        isEmailValid
            && isPasswordValid
            && !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
            && hasAtLeastOneCertification
            && !selectedDomains.isEmpty
            && !isLoading
    }

    public var body: some View {
        ZStack {
            ColorPalette.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Top switch link to client registration
                    HStack {
                        Button(action: onSwitchToClient) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left")
                                Text("Looking for support? Sign up as Client")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(ColorPalette.calmingCyan)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(ColorPalette.warmCharcoal.opacity(0.8))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(ColorPalette.cardBorder, lineWidth: 1)
                            )
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Header with prompt explaining coach signup & extra fields
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 40))
                            .foregroundColor(ColorPalette.sageGreen)

                        Text("Coach Sign Up")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.textPrimary)

                        Text("Professional coach registration requires ICF credential verification, specialties, and hourly rate.")
                            .font(.subheadline)
                            .foregroundColor(ColorPalette.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Form Card
                    GlassCard(style: .elevated, cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 18) {
                            // Section: Personal Information
                            Text("Coach Profile Details")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorPalette.calmingCyan)

                            // First Name (own line)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("First Name")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)
                                TextField("Enter first name", text: $firstName)
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .foregroundColor(ColorPalette.textPrimary)
                            }

                            // Last Name (own line)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Last Name")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)
                                TextField("Enter last name", text: $lastName)
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .foregroundColor(ColorPalette.textPrimary)
                            }

                            // Email Address (own line)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email Address")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                TextField("coach@example.com", text: $email)
                                    .textContentType(.emailAddress)
                                    #if os(iOS)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    #endif
                                    .autocorrectionDisabled()
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .foregroundColor(ColorPalette.textPrimary)
                            }

                            // Password (own line)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password (9 to 32 characters)")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                SecureField("Enter password", text: $password)
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .foregroundColor(ColorPalette.textPrimary)
                            }

                            // Profile Photo URL (own line, optional)
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

                            // Country Code (own line)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Country Code (2-letter ISO, e.g. US)")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                TextField("US", text: $countryCode)
                                    .autocorrectionDisabled()
                                    #if os(iOS)
                                    .textInputAutocapitalization(.characters)
                                    #endif
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .foregroundColor(ColorPalette.textPrimary)
                            }

                            // Timezone (own line)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Timezone")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                TextField("Timezone", text: $timezone)
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .foregroundColor(ColorPalette.textPrimary)
                            }

                            // Gender (own line)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Gender (Optional)")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                HStack(spacing: 6) {
                                    genderPill(id: "MALE", label: "Male")
                                    genderPill(id: "FEMALE", label: "Female")
                                    genderPill(id: "NON_BINARY", label: "Non-Binary")
                                    genderPill(id: "PREFER_NOT_TO_SAY", label: "Prefer not")
                                }
                            }

                            Divider()
                                .background(ColorPalette.cardBorder)
                                .padding(.vertical, 4)

                            // Section: Credentials
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ICF Credentials (Check all that apply)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(ColorPalette.calmingCyan)

                                Text("Select at least one credential level currently held.")
                                    .font(.caption2)
                                    .foregroundColor(ColorPalette.textSecondary)
                            }

                            // Checkboxes: ACC, PCC, MCC, ACTC
                            VStack(spacing: 8) {
                                icfCheckbox(
                                    isChecked: $icfAcc,
                                    acronym: "ACC",
                                    title: "Associate Certified Coach",
                                    hours: "60+ training hrs, 100+ coaching hrs"
                                )
                                icfCheckbox(
                                    isChecked: $icfPcc,
                                    acronym: "PCC",
                                    title: "Professional Certified Coach",
                                    hours: "125+ training hrs, 500+ coaching hrs"
                                )
                                icfCheckbox(
                                    isChecked: $icfMcc,
                                    acronym: "MCC",
                                    title: "Master Certified Coach",
                                    hours: "200+ training hrs, 2,500+ coaching hrs"
                                )
                                icfCheckbox(
                                    isChecked: $icfActc,
                                    acronym: "ACTC",
                                    title: "Advanced Certification in Team Coaching",
                                    hours: "Team coaching competency credential"
                                )
                            }

                            // Large Text Box for Credential Details
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Credential Details & Certificate Identifiers")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                ZStack(alignment: .topLeading) {
                                    if credentialDetails.isEmpty {
                                        Text("Enter ICF credential IDs, dates of issuance, certifying chapters, or training institutions...")
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

                            // Bio Section (Large Text Box)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Biography & Coaching Philosophy")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                ZStack(alignment: .topLeading) {
                                    if biography.isEmpty {
                                        Text("Share your coaching background, philosophy, focus areas, and approach with clients...")
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

                            // Hourly Rate (own line)
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

                            // Domain Tags Multi-Selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Coaching Domains (Select at least 1)")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                                    ForEach(availableDomains, id: \.0) { domain in
                                        let isSelected = selectedDomains.contains(domain.0)
                                        Button {
                                            if isSelected {
                                                if selectedDomains.count > 1 {
                                                    selectedDomains.remove(domain.0)
                                                }
                                            } else {
                                                selectedDomains.insert(domain.0)
                                            }
                                        } label: {
                                            Text(domain.1)
                                                .font(.caption)
                                                .fontWeight(isSelected ? .semibold : .regular)
                                                .foregroundColor(isSelected ? ColorPalette.textPrimary : ColorPalette.textMuted)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(isSelected ? ColorPalette.calmingCyan.opacity(0.3) : ColorPalette.warmCharcoal)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(isSelected ? ColorPalette.calmingCyan : ColorPalette.cardBorder, lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }

                            // Error banner
                            if let error = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(ColorPalette.mutedLavender)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(ColorPalette.mutedLavender)
                                }
                            }

                            // Submit Button
                            AnonyButton(
                                title: "Submit Coach Registration",
                                systemImage: "checkmark.seal.fill",
                                variant: .primary,
                                size: .large,
                                isLoading: isLoading,
                                isDisabled: !canSubmit
                            ) {
                                submitRegistration()
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

    private func genderPill(id: String, label: String) -> some View {
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

    private func icfCheckbox(
        isChecked: Binding<Bool>,
        acronym: String,
        title: String,
        hours: String
    ) -> some View {
        Button {
            isChecked.wrappedValue.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked.wrappedValue ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked.wrappedValue ? ColorPalette.sageGreen : ColorPalette.textMuted)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(acronym)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorPalette.textPrimary)
                        Text("• " + title)
                            .font(.caption)
                            .foregroundColor(ColorPalette.textSecondary)
                    }
                    Text(hours)
                        .font(.caption2)
                        .foregroundColor(ColorPalette.textMuted)
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

    private func submitRegistration() {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil

        let rate = Double(hourlyRateText) ?? 150.0
        let primaryLevel = icfMcc ? "MCC" : (icfPcc ? "PCC" : (icfActc ? "ACTC" : "ACC"))

        let payload = CoachRegistrationPayload(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            photoUrl: photoUrl.isEmpty ? nil : photoUrl,
            gender: gender.isEmpty ? nil : gender,
            countryCode: countryCode.isEmpty ? nil : countryCode.uppercased(),
            icfLevel: primaryLevel,
            icfAcc: icfAcc,
            icfPcc: icfPcc,
            icfMcc: icfMcc,
            icfActc: icfActc,
            credentialDetails: credentialDetails.isEmpty ? nil : credentialDetails,
            domainCodes: Array(selectedDomains),
            timezone: timezone.isEmpty ? TimeZone.current.identifier : timezone,
            biography: biography.isEmpty ? nil : biography,
            hourlyRate: rate
        )

        Task { @MainActor in
            do {
                let session = try await authService.registerCoach(payload: payload)
                isLoading = false
                onSuccess(session)
            } catch let error as AuthError {
                isLoading = false
                errorMessage = error.localizedDescription
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
