# AGENTS.md - Frontend Android

## Commands
```bash
# Build debug APK
make build

# Run unit tests
make test

# Run Android lint
make lint

# Launch dev / open project in Android Studio
make dev
```

## Boundaries

### Always do
- Target Android 14+ (minSdk 26, targetSdk 35) using pure Jetpack Compose and Kotlin Coroutines/Flow.
- Strictly adhere to the Tranquil Theme Palette:
  - Midnight Slate (`#0B0F19`), Warm Charcoal (`#161B26`), Elevated Card (`#1E2536`).
  - Sage Healing Green (`#34D399`), Calming Cyan (`#38BDF8`), Muted Lavender (`#A78BFA`).
- Follow zero-anxiety UI principles: gentle transitions, no jarring alerts, soft pulsing indicators, respectful copy.
- Enforce Zero-PII client requirements: anonymous users have only random pseudonyms/aliases and procedural avatars.
- Store anonymous session tokens and keys securely using `EncryptedSharedPreferences` or the Android Keystore.
- Model UI state immutably using Kotlin `data class` with `StateFlow`.

### Ask first
- Introducing third-party Android libraries or SDKs beyond `livekit-android`.

### Never do
- Prompt clients for PII (real names, emails, phone numbers, or social logins) in client flows.
- Use XML-based legacy layouts when Jetpack Compose is available.
- Store credentials, tokens, or private keys in unencrypted `SharedPreferences`.

## Project Structure
```text
app/src/main/java/com/anony/android/
  ├── MainActivity.kt          # Compose ComponentActivity entry point
  ├── ui/theme/                # Tranquil theme tokens, typography, and shapes
  ├── components/              # Reusable Compose widgets (AnonyButton, GlassCard)
  ├── models/                  # AnonymousUser, Coach, Session
  └── services/                # EncryptedStorage, ApiClient, LiveKitManager
```
