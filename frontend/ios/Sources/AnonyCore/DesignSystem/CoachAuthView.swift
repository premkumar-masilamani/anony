import SwiftUI

/// View facilitating coach registration and ICF credential submission (Issue #17).
public struct CoachAuthView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var icfLevel: String = "ACC"
    @State private var credentialId: String = ""
    @State private var hourlyRateText: String = "150"
    @State private var selectedDomains: Set<String> = ["CAREER", "LEADERSHIP"]
    @State private var biography: String = ""
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
                            // Names
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("First Name")
                                        .font(.caption)
                                        .foregroundColor(ColorPalette.textSecondary)
                                    TextField("First", text: $firstName)
                                        .padding(10)
                                        .background(ColorPalette.warmCharcoal)
                                        .cornerRadius(8)
                                        .foregroundColor(ColorPalette.textPrimary)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Last Name")
                                        .font(.caption)
                                        .foregroundColor(ColorPalette.textSecondary)
                                    TextField("Last", text: $lastName)
                                        .padding(10)
                                        .background(ColorPalette.warmCharcoal)
                                        .cornerRadius(8)
                                        .foregroundColor(ColorPalette.textPrimary)
                                }
                            }

                            // Email
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

                            // Password
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

                            // ICF Credential Level Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ICF Credential Level")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                Picker("ICF Level", selection: $icfLevel) {
                                    Text("ACC").tag("ACC")
                                    Text("PCC").tag("PCC")
                                    Text("MCC").tag("MCC")
                                    Text("ACTC").tag("ACTC")
                                }
                                .pickerStyle(.segmented)
                            }

                            // Credential ID
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ICF Credential ID")
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.textSecondary)

                                TextField("e.g. ICF-982341", text: $credentialId)
                                    .padding(10)
                                    .background(ColorPalette.warmCharcoal)
                                    .cornerRadius(8)
                                    .foregroundColor(ColorPalette.textPrimary)
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

    private func submitRegistration() {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil

        let rate = Double(hourlyRateText) ?? 150.0
        let payload = CoachRegistrationPayload(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            icfLevel: icfLevel,
            credentialDetails: credentialId.isEmpty ? nil : credentialId,
            domainCodes: Array(selectedDomains),
            timezone: TimeZone.current.identifier,
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
