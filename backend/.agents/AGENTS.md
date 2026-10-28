# AGENTS.md - Backend

## Commands
```bash
# Start Spring Boot app in dev mode (hot-reloading)
make dev

# Run full JUnit test suite
make test

# Run tests + generate JaCoCo coverage report
make coverage

# Run Checkstyle, PMD, and SpotBugs
make lint
```

## Boundaries

### Always do
- Use `UUID` for entity IDs and `Instant` / `ZonedDateTime` (UTC) for timestamps.
- Use `BigDecimal` for monetary amounts / prices (or integer cents when specified in domain contracts).
- Enforce strict layer boundaries: `api` depends on `domain`, `persistence`, and `common`; `persistence` depends on `common`; `common` is completely self-contained.
- Ensure all Java files contain exactly one Java type definition (only one class, record, interface, or enum per file) with no nested or extra package-private helper type definitions.
- Ensure all code (including tests and newly generated files) fully conforms to Checkstyle, PMD, and Spotless formatting rules. Fix code quality warnings in the source code rather than suppressing them.
- Use descriptive variable and parameter names: Always use full, readable domain names (e.g. `coachAvailability` instead of `ca`, `anonymousUser` instead of `u`, `ledgerTransaction` instead of `lt`).
- Structure conditional branching so the `if` block executes the primary business logic (happy path), while the `else` block handles error, warning, fallback, or insufficient data conditions.
- Fail fast immediately on application startup or execution if any required configuration, environment variable, or parameter is missing or unexpanded (e.g. `${VAR}`).
- Use Apache Commons Lang `StringUtils` (`org.apache.commons.lang3.StringUtils`) for string blank/empty checks instead of custom utility classes.
- When testing controllers with standalone `MockMvcBuilders.standaloneSetup()`, register `AuthenticationPrincipalArgumentResolver` via `.setCustomArgumentResolvers(...)` so `@AuthenticationPrincipal` correctly resolves mock principals.
- Use concrete DTO records (e.g. `ErrorResponse`) for API error payloads in controller `@ExceptionHandler` methods instead of `java.util.Map` to comply with PMD `LooseCoupling` rules.
- Use `%n` or direct string concatenation rather than text block `.formatted(...)` with implicit `\n` in test payloads to avoid SpotBugs `VA_FORMAT_STRING_USES_NEWLINE` warnings.
- Keep PMD tasks configured with `classpath = files()` and exclude `ImplicitFunctionalInterface` in `pmd-ruleset.xml` to prevent ASM bytecode inspection `StackOverflowError` on Java 27 classes.
- When creating coach profiles, preserve the `coaches_icf_credential_check` constraint requiring at least one ICF credential boolean (`icf_acc`, `icf_pcc`, `icf_mcc`, or `icf_actc`) to be true, and ensure `user_role` matches `COACH` to satisfy the composite foreign key `(user_id, user_role)`.
- When enforcing fair-use quotas (e.g. 14-day cadence cooldown, 6-session lifetime cap), throw domain exceptions translated to HTTP 409 Conflict with structured DTO responses containing exact remaining cooldown days and suggested migration actions.
- When aggregating or grouping domain records in services (such as evaluating the mandatory 60-minute monthly free session pledge per UTC `YearMonth`), prefer `java.util.List` collections over `java.util.Map` to comply with PMD `LooseCoupling` rules.
- Include generous structured SLF4J log statements (`DEBUG`, `INFO`, and `WARN`) across all Java classes containing functional logic (controllers, services, schedulers, security filters, and interceptors) so runtime execution, state transitions, and validation/error boundaries are clearly observable.

### Ask first
- Adding third-party libraries/dependencies to `build.gradle`.

### Never do
- Use JPA `ddl-auto` to generate schemas (always set to `none`).
- Omit `@Column(length = N)` on Strings or `precision` / `scale` on BigDecimals.
- Use cryptic or single-letter variable names for domain models, method parameters, or stream/lambda expressions.
- Place error, warning, or insufficient data handling inside the `if` block while relegating the actual business logic to the `else` block.
- Define default values for configuration variables, environment variables, entity fields, method parameters, or request parameters unless explicitly requested. Silent fallbacks and default property values are strictly forbidden.
- Add `isConfigured()` checks on config beans or services; required environment variables are mandatory and the application must fail to start if they are missing.
- Add empty `private ClassName() {}` constructors to static utility or constant classes unless needed by the application.

## Project Structure
```text
src/main/java/com/anony/api/         # REST API layer (controllers, services, DTOs)
src/main/java/com/anony/domain/      # Core business domain logic and services
src/main/java/com/anony/persistence/ # DB layer (JPA entities, repositories)
src/main/java/com/anony/common/      # Shared cross-cutting constants and enums
```

## Testing
- **Framework**: JUnit 5 + JaCoCo
- **Coverage threshold**: 100% line/branch coverage for non-DTO packages.
- **Mocking**: Use `@MockBean` / Mockito. Ensure no live database connections in unit tests.
