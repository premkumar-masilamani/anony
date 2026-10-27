# AGENTS.md - Frontend iOS

## Commands
```bash
# Compile Swift package and modules
make build

# Run mobile unit tests
make test

# Run Swift static analysis / lint
make lint

# Launch dev / open project in Xcode
make dev
```

## Boundaries

### Always do
- Target iOS 17.0+ using pure SwiftUI and Swift Concurrency (`async`/`await`, `@MainActor`).
- Strictly adhere to the Tranquil Theme Palette:
  - Midnight Slate (`#0B0F19`), Warm Charcoal (`#161B26`), Elevated Card (`#1E2536`).
  - Sage Healing Green (`#34D399`), Calming Cyan (`#38BDF8`), Muted Lavender (`#A78BFA`).
- Follow zero-anxiety UI principles: gentle transitions, no jarring alerts, soft pulsing indicators, respectful copy.
- Maintain calming breathing pacing (3.0s–4.0s easing duration) for ambient pulsing aura indicators.
- Omit legacy `UIApplicationSceneManifest` in `Info.plist` when using pure SwiftUI `@main struct App` lifecycle to prevent empty white scene initialization.
- Store anonymous session tokens and keys securely in iOS Keychain via `kSecClassGenericPassword`.
- Ensure all business models conform to `Codable`, `Sendable`, and `Identifiable` where applicable.
- Write unit tests using the modern Swift Testing framework (`import Testing`, `@Suite`, `@Test`) under `Tests/AnonyCoreTests/`.
- When querying `kSecClassGenericPassword`, always supply both `kSecAttrService` and `kSecAttrAccount` to guarantee account isolation and prevent cross-item query ambiguity in multi-attribute Keychain sessions.
- Annotate Swift Testing suites (`@Suite`) interacting with Keychain or shared singletons with `.serialized` to prevent parallel execution race conditions.
- Enforce password boundary rules with simple count checks (`password.count > 8 && password.count <= 32`) without adding extraneous complexity rules unless explicitly specified.
- Extract high-level navigation and routing state machines (e.g. flow views like `ClientRootFlowView`) into the `AnonyCore` library rather than keeping them private inside executable entry points (`ContentView`) to ensure full Swift Testing coverage.

### Ask first
- Introducing third-party Swift Package dependencies beyond `livekit-client-swift`.

### Never do
- Use UIKit wrappers when native SwiftUI equivalents are available in iOS 17+.
- Hardcode raw colors in views; always reference `ColorPalette`.
- Store credentials, tokens, or private keys in `UserDefaults`.

## Project Structure
```text
AnonyApp.xcodeproj/     # Native iOS application project bundle
App/                    # @main SwiftUI App entry point and primary screens
Sources/AnonyCore/      # Shared Swift module
  ├── DesignSystem/     # ColorPalette, AnonyButton, GlassCard, AuraView, Stepper, Shell, FlowCoordinator, VisualTemplates
  ├── Models/           # AnonymousUser, AuthSession, Coach, CoachingSession, OnboardingPreferences, StruggleCategory, PricingTier
  └── Services/         # IdentityService, AuthService, OnboardingService, KeychainStorage, ApiClient, LiveKitRoomManager
Tests/AnonyCoreTests/   # Swift Testing suites (Registration, Identity, Stepper, Shell, Models, Onboarding)
```
