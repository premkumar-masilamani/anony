# AGENTS.md

## Commands
```bash
# Start Postgres container + run migrations + seed data
make run_database

# Connect to psql inside the running DB container
make connect_database

# Start Spring Boot backend with continuous live reload
make run_backend

# Install dependencies and start Vite frontend dev server
make run_frontend

# Open or build iOS mobile development environment
make run_ios

# Open or build Android mobile development environment
make run_android

# Run tests and static analysis
make test
make lint
make build
```

## Boundaries

### Always do
- Read the corresponding `.agents/AGENTS.md` file inside the `backend/`, `frontend/web/`, `frontend/ios/`, `frontend/android/`, or `database/` submodules before modifying their files.
- Fail fast immediately on startup or invocation if any required configuration, environment variable, or parameter is missing or unexpanded (e.g. `${VAR}`).
- Use `org.apache.commons.lang3.StringUtils` for string blank/empty checks in the backend rather than custom string utility classes.

### Ask first
- Modifying core project structure, changing database migration tooling, or adding new third-party dependencies.

### Never do
- Commit secrets, private API keys, or `.env` files.
- Apply database migrations (all migrations are strictly manual—never ever apply them).
- Default any variable, configuration property, environment variable, or method/request parameter unless explicitly specified. Silent fallbacks are strictly prohibited.
- Add `isConfigured()` helper methods or runtime configuration presence checks in services; all required environment variables are mandatory at startup.

## Project Structure
```text
backend/           # Spring Boot 4.1 / Java 27 / Gradle
frontend/web/      # React 19 / Vite / TypeScript / Tailwind
frontend/ios/      # iOS 17+ / SwiftUI / Swift Package Manager
frontend/android/  # Android 14+ / Kotlin / Jetpack Compose
database/          # Postgres 17 / Docker / migrate
.agents/           # Agent rules and context
```

## Git Workflow
- **Branch naming**: `feature/[short-desc]` or `fix/[short-desc]`.
- **Commit format**: Imperative mood (e.g. `Initialize backend skeleton`).
- **PR conventions**: One logical change per PR. Never push directly to main.
