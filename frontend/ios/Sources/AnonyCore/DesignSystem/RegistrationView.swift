import SwiftUI

public struct RegistrationView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    private let authService: AuthServiceProtocol
    private let onSuccess: (AuthSession) -> Void

    public init(
        authService: AuthServiceProtocol = MockAuthService(),
        onSuccess: @escaping (AuthSession) -> Void
    ) {
        self.authService = authService
        self.onSuccess = onSuccess
    }

    private var isPasswordValid: Bool {
        RegistrationValidator.isValidPassword(password)
    }

    private var isEmailValid: Bool {
        RegistrationValidator.isValidEmail(email)
    }

    private var canSubmit: Bool {
        isEmailValid && isPasswordValid && !isLoading
    }

    public var body: some View {
        ZStack {
            ColorPalette.backgroundGradient
                .ignoresSafeArea()

            // Ambient background aura
            VStack {
                HStack {
                    Spacer()
                    PulsingAuraView(
                        color: ColorPalette.calmingCyan,
                        diameter: 240,
                        cycleDuration: 4.0,
                        scaleRange: 0.9...1.1
                    )
                    .offset(x: 50, y: -40)
                }
                Spacer()
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 44))
                            .foregroundColor(ColorPalette.calmingCyan)
                            .padding(.top, 40)

                        Text("Welcome to Anony")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.textPrimary)

                        Text("Create your account securely. An anonymous alias and avatar will be assigned automatically.")
                            .font(.subheadline)
                            .foregroundColor(ColorPalette.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Form Card
                    GlassCard(style: .elevated, cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(ColorPalette.textSecondary)

                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(ColorPalette.textMuted)

                                    TextField("user@example.com", text: $email)
                                        .textContentType(.emailAddress)
                                        #if os(iOS)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        #endif
                                        .autocorrectionDisabled()
                                        .foregroundColor(ColorPalette.textPrimary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(ColorPalette.warmCharcoal)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(ColorPalette.cardBorder, lineWidth: 1)
                                )
                                
                                if !email.isEmpty && !isEmailValid {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle")
                                            .font(.caption2)
                                            .foregroundColor(ColorPalette.calmingCyan)

                                        Text("Please enter a valid email (e.g. user@example.com).")
                                            .font(.caption2)
                                            .foregroundColor(ColorPalette.textMuted)
                                    }
                                    .padding(.top, 2)
                                }
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(ColorPalette.textSecondary)

                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(ColorPalette.textMuted)

                                    SecureField("9 to 32 characters", text: $password)
                                        .foregroundColor(ColorPalette.textPrimary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(ColorPalette.warmCharcoal)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(ColorPalette.cardBorder, lineWidth: 1)
                                )

                                // Password requirements guide
                                HStack(spacing: 6) {
                                    Image(systemName: isPasswordValid ? "checkmark.circle.fill" : "info.circle")
                                        .font(.caption2)
                                        .foregroundColor(isPasswordValid ? ColorPalette.sageGreen : ColorPalette.textMuted)

                                    Text("Must be longer than 8 characters and up to 32 characters.")
                                        .font(.caption2)
                                        .foregroundColor(isPasswordValid ? ColorPalette.sageGreen : ColorPalette.textMuted)
                                }
                                .padding(.top, 2)
                            }

                            // Error message (if any)
                            if let error = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(ColorPalette.mutedLavender)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(ColorPalette.mutedLavender)
                                }
                                .padding(.top, 4)
                            }

                            // Submit Button
                            AnonyButton(
                                title: "Complete Registration",
                                systemImage: "arrow.right.circle.fill",
                                variant: .primary,
                                size: .large,
                                isLoading: isLoading,
                                isDisabled: !canSubmit
                            ) {
                                performRegistration()
                            }
                            .padding(.top, 8)
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 20)

                    // Tranquil Privacy Guarantee Pill
                    HStack(spacing: 8) {
                        TagPillView(
                            text: "Keychain Encrypted",
                            systemImage: "lock.shield.fill",
                            variant: .cyan
                        )
                        TagPillView(
                            text: "Procedural Avatar",
                            systemImage: "sparkles",
                            variant: .sage
                        )
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func performRegistration() {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let session = try await authService.register(email: email, password: password)
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
