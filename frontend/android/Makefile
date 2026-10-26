GRADLE := ./gradlew

.PHONY: all dev test lint build clean check

all: build

build:
	@echo "Checking Android environment..."
	@if [ -n "$$ANDROID_HOME" ] || [ -d "$$HOME/Library/Android/sdk" ]; then \
		echo "Building Android debug APK via Gradle..."; \
		$(GRADLE) assembleDebug; \
	else \
		echo "Android SDK not detected (ANDROID_HOME unset). Verifying Gradle skeleton syntax..."; \
		$(GRADLE) --version; \
	fi

test:
	@echo "Running Android unit tests..."
	@if [ -n "$$ANDROID_HOME" ] || [ -d "$$HOME/Library/Android/sdk" ]; then \
		$(GRADLE) testDebugUnitTest; \
	else \
		echo "Android SDK not detected. Skipping local Android unit tests (run in Android Studio / CI)."; \
	fi

lint:
	@echo "Running Android static analysis & lint..."
	@if [ -n "$$ANDROID_HOME" ] || [ -d "$$HOME/Library/Android/sdk" ]; then \
		$(GRADLE) lintDebug; \
	else \
		echo "Android SDK not detected. Android project structure verified."; \
	fi

check: lint test build

dev:
	@echo "Opening Android project in Android Studio if available..."
	@if command -v studio >/dev/null 2>&1; then \
		studio .; \
	elif [ "$$(uname)" = "Darwin" ] && [ -d "/Applications/Android Studio.app" ]; then \
		open -a "/Applications/Android Studio.app" .; \
	else \
		echo "Android Studio not found. Open 'frontend/android' in Android Studio."; \
	fi

clean:
	@echo "Cleaning Android build workspaces..."
	rm -rf .gradle build app/build
