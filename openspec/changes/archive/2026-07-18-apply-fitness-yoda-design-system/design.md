## Context

The Flutter application already has authenticated routing, Bloc/Cubit state, API repositories, and feature screens. Its presentation is still close to default Material styling. A complete visual package now exists under `app/design/`, including tokens, component guidance, screen mapping, cropped references, and six ordered implementation prompts.

This change is presentation-focused and crosses the app theme, shared widgets, router shell, auth screens, home, and schedule screens. Existing behavior remains governed by `openspec/specs/`, especially `user-auth`, `mobile-auth`, `mobile-app-shell`, and schedule/session capabilities. The implementation remains under `app/fitness_app/` and follows `docs/mobile/tooling.md`.

### Source-of-truth hierarchy

1. `openspec/specs/**` and current API/Bloc contracts define product behavior.
2. `app/design/tokens.md` defines visual constants.
3. `app/design/components/*.md` defines reusable component appearance and states.
4. `app/design/mapping-fitness-yoda.md` defines how reference patterns map to product screens and which reference features are excluded.
5. `app/design/ref_login.png` is the primary Login composition reference; `app/design/crops/*.png` provides component anchors.
6. `app/design/prompts/01-theme-tokens.md` through `06-home-schedule.md` define the ordered implementation scope.

If a visual instruction conflicts with a behavioral contract, preserve the behavior and adapt the presentation. The prompts do not authorize API, repository, validation, permission, or Bloc/Cubit contract changes.

## Goals / Non-Goals

**Goals:**

- Establish a consistent Fitness Yoda light theme using the documented palette, spacing, radii, typography scale, and soft surfaces.
- Provide reusable button, card, and input primitives with explicit loading, disabled, validation, and interaction states.
- Introduce a role-aware bottom navigation shell without weakening existing authentication redirects.
- Apply the design language to Login, Register, Home, and key schedule/session screens.
- Deliver the work in six isolated stages, each analyzed and visually verified before the next stage starts.

**Non-Goals:**

- Changing NestJS endpoints, DTOs, token handling, repositories, or persistence.
- Replacing Bloc/Cubit, `go_router`, or the current feature architecture.
- Adding reference-product features such as BMI, nutrition, workout plans, or anatomical graphics.
- Pixel-perfect duplication of the reference application.
- Introducing `google_fonts`, Riverpod, freezed, hive, or get_it.
- Redesigning every mobile feature in this change.

## Decisions

### 1. Keep `app/design/**` as the visual source of truth

Implementation artifacts will reference the existing design pack rather than copy all token and component details into OpenSpec. This avoids two independently editable design definitions while ensuring each stage reloads the relevant documents and image crops.

Alternative considered: duplicate all design values in the OpenSpec specs. Rejected because copied visual details would drift from `app/design/` and make future design revisions ambiguous.

### 2. Implement one ordered stage per Agent run

The six files under `app/design/prompts/` remain the execution units and must run in numeric order. Each run completes only one stage, performs static analysis and simulator validation, updates that stage's task checkboxes, reports the result, and stops before the next stage.

Alternative considered: let `/opsx:apply` implement every remaining task in one run. Rejected because a large UI rewrite reduces visual review opportunities and makes regressions harder to isolate.

### 3. Build primitives before screen reskins

Theme tokens are applied first, followed by shared buttons, then cards and inputs. Navigation and screen-level work consume those primitives rather than introducing local copies. Shared presentation widgets belong in the existing app/core widget convention discovered during implementation; feature-specific composition remains in its feature presentation layer.

Alternative considered: style each screen independently. Rejected because it creates duplicated colors, shapes, loading states, and inconsistent future maintenance.

### 4. Preserve state and data boundaries

Presentation changes consume existing Bloc/Cubit state and repository APIs. Page/View separation and current provider ownership remain intact. Widgets must not perform networking, token storage, or domain-state mutation outside existing callbacks.

Alternative considered: refactor state management while redesigning screens. Rejected because it expands scope and makes functional regressions difficult to attribute.

### 5. Add navigation as an authenticated shell

The bottom navigation will use `go_router` shell routing, preferably `StatefulShellRoute` when compatible with the current router. Existing destinations and auth redirects remain authoritative. Tab availability can vary by trainer/student role, and logout/profile behavior moves only when the existing contracts can be preserved.

Alternative considered: maintain tab state manually in one screen. Rejected because it duplicates router state and weakens deep-link behavior.

### 6. Validate behavior and appearance at every stage

After each stage:

- run `flutter analyze` scoped to changed files when supported, followed by the project-standard analysis needed to establish a clean result;
- run relevant existing tests when routing, validation, or reusable widget behavior changes;
- launch or reuse a simulator through the available Dart/Flutter tooling;
- inspect the affected screens at representative loading, disabled, error/validation, empty, and populated states where available;
- compare the result against the referenced crops and document any intentional deviation.

A stage is not marked complete until analysis succeeds and its affected UI has been inspected. Functional smoke checks must confirm that login/register, route protection, logout, booking/slot actions, and session navigation still work when those areas are touched.

### 7. Translate the Login reference, do not clone its product

Stage 05 uses `app/design/ref_login.png` for composition: a branded wellness hero above a rounded white authentication panel with centered welcome copy, icon-led fields, a stadium primary action, and a registration link. Fitness Yoda copy, palette, components, and existing auth behavior remain authoritative.

The FitTrack brand, illustration, Google Sign-In, password recovery, and `OR` separator are not implementation requirements. Unsupported actions must not appear as decorative or non-functional controls. The layout must remain scrollable and usable on compact devices and with the software keyboard visible.

## Risks / Trade-offs

- [Theme changes affect screens outside the current stage] → Keep theme edits token-driven, inspect representative existing screens, and avoid opportunistic layout changes.
- [Shared widget replacement changes validation or submit behavior] → Preserve controllers, validators, focus behavior, callbacks, and Bloc/Cubit events; test loading and disabled states.
- [Role-aware tabs diverge from route permissions] → Derive visible destinations from existing authenticated user roles while retaining router guards as the security boundary.
- [Image references are interpreted differently across sessions] → Re-read the exact crop files for every stage and record intentional deviations in the stage result.
- [One OpenSpec apply run continues into multiple stages] → Treat the end of each numbered stage as a mandatory execution stop and start the next stage only in a new Agent run.
- [Simulator data is unavailable for populated states] → Use existing local API fixtures/accounts where available; do not add backend behavior merely to support screenshots.

## Migration Plan

1. Apply theme tokens without changing screen structure.
2. Introduce shared buttons and migrate auth CTAs.
3. Introduce shared cards/inputs and migrate auth fields.
4. Add the authenticated navigation shell around existing destinations.
5. Reskin auth screen composition.
6. Reskin Home and key schedule/session surfaces.

Each stage must leave the Flutter app analyzable and runnable. If a stage regresses behavior, revert only that stage's presentation changes or restore the prior widget/router composition while keeping already verified lower-level primitives.

## Open Questions

- Confirm the exact trainer/student tab sets during stage 04 from the current routes and role capabilities.
- Decide during stage 02 whether a secondary button is needed by existing screens or should remain deferred.
- Decide during stage 05 whether an existing local asset can support the auth hero; otherwise use an abstract branded composition without adding a random stock illustration or new dependency.
