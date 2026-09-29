## Why

The Flutter app currently relies on mostly default Material styling, while the prepared Fitness Yoda design pack defines a coherent product language for auth, navigation, home, and schedule flows. Applying that language incrementally will make the existing mobile shell visually consistent without coupling the redesign to API or state-management changes.

## What Changes

- Introduce Fitness Yoda theme tokens and explicit Material color/theme configuration.
- Add reusable primary/secondary buttons, soft cards, and card-style inputs.
- Add a role-aware authenticated bottom-navigation shell around existing routes.
- Reskin Login, Register, Home, and key schedule/session screens using the prepared design references.
- Execute the redesign as six ordered, independently verifiable stages based on `app/design/prompts/01-theme-tokens.md` through `06-home-schedule.md`.
- Preserve existing API contracts, Bloc/Cubit behavior, validation, routing guards, and domain behavior.

## Capabilities

### New Capabilities

- `mobile-design-system`: Defines the shared Fitness Yoda visual language, reusable Flutter components, and visual acceptance behavior for auth, home, and schedule surfaces.

### Modified Capabilities

- `mobile-app-shell`: Adds a role-aware bottom navigation shell while preserving authenticated route protection and existing feature destinations.

## Impact

- Flutter-only implementation under `app/fitness_app/`, primarily theme, shared widgets, router shell, and presentation screens.
- `app/design/**` is the visual source of truth; `docs/mobile/tooling.md`, `openspec/specs/user-auth/spec.md`, and the existing mobile specs remain behavioral context.
- No planned changes to NestJS APIs, persistence, generated contracts, or authentication payloads.
- No new runtime dependency is required for the first iteration.

## Non-goals

- Adding BMI, nutrition, workout-plan, anatomical illustration, or other reference-app features.
- Rewriting feature architecture, Bloc/Cubit logic, repositories, or API clients.
- Pixel-perfect copying of reference branding or marketing copy.
- Redesigning web applications or changing backend behavior.
- Adding a custom font package in this change.
