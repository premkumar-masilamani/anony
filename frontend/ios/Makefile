SWIFT ?= swift
XCODEBUILD ?= xcodebuild

.PHONY: dev test lint build clean check

all: build

build:
	@echo "Compiling mobile Swift packages..."
	@if command -v $(XCODEBUILD) >/dev/null 2>&1 && $(XCODEBUILD) -version >/dev/null 2>&1; then \
		echo "Building iOS App via xcodebuild..."; \
		$(XCODEBUILD) -scheme AnonyApp -destination 'generic/platform=iOS Simulator' build; \
	else \
		echo "Compiling Swift core packages via swift build..."; \
		$(SWIFT) build; \
	fi

test:
	@echo "Running mobile test suites..."
	@$(SWIFT) test

lint:
	@echo "Linting Swift codebase..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
	else \
		echo "Swiftlint not found; validating via Swift compiler..."; \
		$(SWIFT) build; \
	fi

check: lint test build

dev:
	@echo "Launching mobile development environment in Xcode..."
	@if [ -d "AnonyApp.xcodeproj" ]; then \
		open AnonyApp.xcodeproj; \
	elif [ -f "Package.swift" ]; then \
		open Package.swift; \
	fi

clean:
	@echo "Cleaning mobile build artifacts..."
	rm -rf .build DerivedData
