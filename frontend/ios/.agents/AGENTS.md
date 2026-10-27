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
- Centralize all API endpoint URLs and route builders in `APIEndpoints` and `APIConfig` under `Sources/AnonyCore/Services/` and reference them across network clients and mock services rather than hardcoding endpoint strings.
- In Swift Concurrency (`Sendable`), avoid using `NSLock` inside `async` methods; prefer immutable values, actor isolation, or `@MainActor` state wrappers.
- Decouple directory, filter, and detail view states into `@MainActor` ObservableObject view models (e.g. `CoachDiscoveryViewModel`, `CoachProfileViewModel`) to enable real-time reactive filtering, slot selection, and clean Swift Testing coverage.
- Store coaching session and booking slots in absolute UTC (`Date`) on domain models (`CoachSlot`), converting dynamically to client local `TimeZone` at the presentation layer with explicit `DateFormatter` configurations.
- In Swift Testing with SwiftUI struct views, avoid `#expect(view != nil)` on non-optional structs; inspect `Mirror(reflecting: view)` or assert state properties directly to prevent compiler comparison warnings.
- Persist authenticated user role (`CLIENT` or `COACH`) in Keychain via `IdentityService` and dynamically route post-login views based on role and verification state (`GET /api/v1/coaches/me`).
- In Anonymous Blind Match flows, prevent direct coach profile browsing and slot reservation; capture struggle prompts and preferred time windows, presenting confirmed session booking details directly.
- In `@MainActor` view models (e.g. `CoachAvailabilityViewModel`), annotate shared static constants with `nonisolated` (`nonisolated public static let`) so SwiftUI view initializers can reference them as default parameter values without Swift 6 actor-isolation warnings.

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
