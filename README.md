# anony

An anonymous, zero-anxiety, zero-PII emotional well-being client and coaching platform.

---

## Architecture Overview

- **`backend/`**: Spring Boot 4.1 / Java 27 / Gradle
- **`frontend/web/`**: React 19 / Vite / TypeScript / Tailwind CSS
- **`frontend/ios/`**: iOS 17+ / SwiftUI / Swift Package Manager
- **`frontend/android/`**: Android 14+ / Kotlin / Jetpack Compose
- **`database/`**: PostgreSQL 17 / Docker / migrate tooling

---

## iOS Mobile Client (`frontend/ios`)

For detailed setup, troubleshooting, and architectural guidelines, see [frontend/ios/README.md](frontend/ios/README.md).

### 1. Prerequisites & Installing Xcode
1. **Install Xcode 15.0+** from the Mac App Store or download from [developer.apple.com/download/all/](https://developer.apple.com/download/all/).
2. **Configure Command Line Tools:**
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license accept
   xcode-select --install
   ```
3. **Install the iOS 17+ Simulator Runtime:**
   - In Xcode: `Settings > Platforms > iOS` (or run `xcodebuild -downloadPlatform iOS`).

### 2. Running in an iOS Simulator
1. Open the project in Xcode:
   ```bash
   make run_ios
   # or: open frontend/ios/Package.swift
   ```
2. Select any **iOS 17+ Simulator** (e.g. *iPhone 15 Pro*) in Xcode's top destination dropdown.
3. Press **`Cmd + R`** (Product > Run).

### 3. Running on a Physical iOS Device Connected to Mac
1. **Enable Developer Mode** on your iPhone/iPad:
   - Go to `Settings > Privacy & Security > Developer Mode` and toggle **ON** (restart device when prompted).
2. **Connect Device:**
   - Plug your iOS device into your Mac via cable.
   - Tap **Trust This Computer** on the device and enter passcode.
3. **Configure Signing in Xcode:**
   - Open `frontend/ios/Package.swift` in Xcode.
   - Go to `Xcode > Settings... > Accounts` and add your Apple ID.
   - Select your personal team under **Signing & Capabilities**.
4. **Deploy & Run:**
   - Select your physical iOS device from Xcode's destination dropdown.
   - Press **`Cmd + R`**.
5. **Trust Developer Certificate (First Run):**
   - On the device, open `Settings > General > VPN & Device Management` and tap **Trust "[Your Apple ID]"**.

---

## General Commands

```bash
# Start backend
make run_backend

# Start web frontend dev server
make run_frontend

# Open iOS mobile development environment
make run_ios

# Run tests and linters across all submodules
make test
make lint
make build
```
