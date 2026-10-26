# AGENTS.md - Frontend

## Commands
```bash
# Start local web development server
make dev_web

# Open or launch iOS mobile environment in Xcode
make dev_ios

# Run all tests (web + ios)
make test

# Run all linters (web + ios)
make lint

# Run all builds (web + ios)
make build
```

## Submodules
- `frontend/web/`: React 19 / Vite / TypeScript / Tailwind web client.
- `frontend/ios/`: iOS 17+ / SwiftUI / Swift Package Manager mobile app.

## Boundaries
- Always read the respective `.agents/AGENTS.md` file inside `frontend/web/` or `frontend/ios/` before modifying client-specific code.
- Enforce Zero-PII across all client implementations.
