# iOS Mobile Client (`frontend/ios`)

The Anony iOS client is built with **SwiftUI**, targeting **iOS 17.0+**, organized around **Swift Package Manager (SPM)**, and strictly engineered for a tranquil, zero-anxiety, and zero-PII client experience.

---

## 1. Prerequisites & Installing Xcode

To develop, build, test, and run the iOS project on macOS, you need **Xcode 15.0+** (supporting iOS 17+ SDKs) and the Xcode Command Line Tools.

### Step 1: Install Xcode
1. **From Mac App Store (Recommended):**
   - Open the **App Store** on your Mac.
   - Search for **Xcode** and click **Get / Install**.
2. **From Apple Developer Portal (Alternative):**
   - Visit [developer.apple.com/download/all/](https://developer.apple.com/download/all/).
   - Sign in with your Apple ID and download the latest stable Xcode release (`.xip` file).
   - Unpack and drag `Xcode.app` into `/Applications`.

### Step 2: Configure Command Line Tools & Active Developer Path
Once installed, open Terminal and point the system developer directory to Xcode:

```bash
# Point xcode-select to your active Xcode installation
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Accept the Xcode license agreement
sudo xcodebuild -license accept

# Install Xcode command line developer tools (if not already installed)
xcode-select --install
```

### Step 3: Install the iOS 17+ Simulator Runtime
1. Launch **Xcode**.
2. In the top menu, navigate to **Xcode > Settings...** (or press `Cmd + ,`).
3. Select the **Platforms** tab.
4. If **iOS 17+** is not already installed, click **Get** or the **+** button at the bottom-left to install the latest **iOS Simulator Runtime**.
5. Alternatively, download via CLI:
   ```bash
   xcodebuild -downloadPlatform iOS
   ```

---

## 2. Quick CLI Commands

From either the repository root or the `frontend/ios` directory:

```bash
# From repository root:
make run_ios    # Launches Xcode with the iOS environment
make test       # Runs tests across all submodules (including iOS)
make lint       # Lints Swift codebase

# From frontend/ios/ directory:
make dev        # Opens Package.swift / Xcode workspace
make build      # Compiles Swift packages via swift build or xcodebuild
make test       # Executes mobile test suites
make lint       # Swiftlint / Swift compiler check
```

---

## 3. Running in an iOS Simulator

### Option A: Using Xcode IDE (Recommended)
1. Open the project in Xcode:
   ```bash
   make dev
   # or: open frontend/ios/Package.swift
   ```
2. Wait for Xcode to resolve Swift Package dependencies (`AnonyCore`).
3. In the top toolbar run destination menu (next to the scheme selector), select any **iOS 17+ Simulator** (e.g., *iPhone 15 Pro*, *iPhone 16*).
4. Build and run by clicking the **Play** button or pressing **`Cmd + R`**.
5. Xcode will automatically boot the iOS Simulator and launch the Anony app.

### Option B: Using the Command Line
1. List available simulator devices:
   ```bash
   xcrun simctl list devices available
   ```
2. Boot a simulator (replace `<device_name_or_udid>` with e.g. `iPhone 15 Pro`):
   ```bash
   xcrun simctl boot "iPhone 15 Pro"
   open -a Simulator
   ```
3. Compile and build the Swift modules:
   ```bash
   swift build
   ```

---

## 4. Running on a Physical iOS Device Connected to Mac

To run and debug the app directly on a physical iPhone or iPad connected to your Mac:

### Step 1: Enable Developer Mode on your iOS Device
Starting in iOS 16+, Developer Mode must be enabled on the physical device:
1. On your iPhone/iPad, open **Settings**.
2. Tap **Privacy & Security**.
3. Scroll to the bottom and tap **Developer Mode**.
4. Toggle **Developer Mode** ON.
5. Restart your device when prompted, and tap **Turn On** upon restart, entering your device passcode.

### Step 2: Connect the Device to Your Mac
1. Connect your iPhone/iPad to your Mac using a USB-C or Lightning cable.
2. If prompted on the iOS device, tap **Trust This Computer** and enter your passcode.
3. If prompted on macOS Finder, click **Trust**.

### Step 3: Configure Code Signing in Xcode
1. Open the iOS project in Xcode:
   ```bash
   open frontend/ios/Package.swift
   ```
2. Add your Apple ID to Xcode:
   - Go to **Xcode > Settings... > Accounts**.
   - Click the **`+`** button and select **Apple ID**.
   - Sign in with your Apple account (free personal accounts work for development).
3. Under the target's **Signing & Capabilities** tab:
   - Ensure **Automatically manage signing** is checked.
   - Select your personal Apple ID under **Team**.
   - (If creating a standalone target, ensure a unique **Bundle Identifier** such as `com.yourname.anony`).

### Step 4: Run the App on the Device
1. In Xcode's top toolbar, click the device selector and choose your connected physical device under the **iOS Devices** list.
2. Press **`Cmd + R`** (or click the **Play** button).
3. Xcode will sign, install, and launch the app on your physical iPhone.

### Step 5: Trust the Developer Profile (First Time Only)
When running for the first time with a free personal developer account, iOS may block launch until trusted:
1. On your iPhone, open **Settings > General > VPN & Device Management**.
2. Under **Developer App**, select your Apple ID email.
3. Tap **Trust "[Your Apple ID]"** and confirm.
4. Launch the Anony app from your home screen or via Xcode.

---

## 5. Architectural Standards & Design Rules
- **iOS 17.0+ & Pure SwiftUI:** No legacy UIKit wrappers when native SwiftUI equivalents are available.
- **Tranquil Theme Palette:**
  - Midnight Slate (`#0B0F19`), Warm Charcoal (`#161B26`), Elevated Card (`#1E2536`)
  - Sage Healing Green (`#34D399`), Calming Cyan (`#38BDF8`), Muted Lavender (`#A78BFA`)
- **Zero Raw Colors:** Never hardcode colors in views; reference `ColorPalette`.
- **Zero-PII Client:** Users never provide real names, emails, or photos. Avatars are 100% procedurally generated.
- **Zero-Anxiety UI:** Respectful copy, gentle spring animations, calming 3.5s breathing aura cycles.
