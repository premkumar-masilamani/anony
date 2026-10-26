# AGENTS.md - Frontend Web

## Commands
```bash
# Install dependencies
make install

# Start local Vite development server
make dev

# Create production build
make build

# Run ESLint validation
make lint

# Run audit, lint, and build checks
make check
```

## Boundaries

### Always do
- Enforce TypeScript strict mode.
- Explicitly fail fast or render informative error UI when required environment variables (e.g. API endpoints) or parameters are missing.
- Ensure all components have associated unit tests.

### Ask first
- Adding new UI libraries or component frameworks.

### Never do
- Default any environment variable, configuration property, state, or API request parameter unless explicitly specified. Silent fallbacks (e.g. empty string fallbacks for API URLs) are strictly forbidden.

## Project Structure
```text
src/components/    # React UI components
src/services/      # API clients (axios/fetch with error handling)
src/App.tsx        # Global state and page layout
```

## Code Style
```tsx
// 4-spaces indentation for TS/TSX; use single quotes; always use semicolons
import React, { useState } from 'react';

export const ExampleComponent = () => {
    const [active, setActive] = useState<boolean>(false);
    return <div className="p-4">{active ? 'Active' : 'Inactive'}</div>;
};
```
```json
// 2-spaces indentation for configuration files
{
  "name": "frontend"
}
```

## Testing
- **Framework**: Vitest / React Testing Library.
- **Universal LocalStorage Mocking**: In Node test environments where global `localStorage` is partially defined but uninitialized, tests running in Node context throw `TypeError` on storage operations. Always define standard mock implementations on both `window.localStorage` and `globalThis.localStorage` in `setupTests.ts`.
