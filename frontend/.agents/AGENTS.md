# AGENTS.md - Frontend

## Commands
```bash
# Start local web development server
make dev_web

# Open or launch iOS mobile environment in Xcode
make dev_ios

# Open or launch Android mobile environment in Android Studio
make dev_android

# Run all tests (web + ios + android)
make test

# Run all linters (web + ios + android)
make lint

# Run all builds (web + ios + android)
make build
```

## Submodules
- `frontend/web/`: React 19 / Vite / TypeScript / Tailwind web client.
- `frontend/ios/`: iOS 17+ / SwiftUI / Swift Package Manager mobile app.
- `frontend/android/`: Android 14+ / Kotlin / Jetpack Compose mobile app.

## Boundaries
- Always read the respective `.agents/AGENTS.md` file inside `frontend/web/`, `frontend/ios/`, or `frontend/android/` before modifying client-specific code.
