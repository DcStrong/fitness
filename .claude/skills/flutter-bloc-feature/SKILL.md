---
name: flutter-bloc-feature
description: >-
  Add or modify a Flutter feature using Bloc/Cubit with Page/View separation,
  Equatable sealed events/states, and repository-backed logic. Use when creating
  screens, blocs, cubits, or feature folders under app/fitness_app. Inspired by
  Very Good Ventures bloc skill; tailored for Fitness Yoda (no Riverpod).
---
<!-- pipil-sync: из .cursor/skills/flutter-bloc-feature/SKILL.md. Правьте источник — копию обновит «Синхронизировать правила». -->

# Flutter Bloc Feature

## Stack lock

- `flutter_bloc` + `bloc` + `equatable` + `bloc_test` + `mocktail`
- **Never** Riverpod / Provider for app state
- No bloc-to-bloc dependencies — share repositories instead

## Layers

| Layer | Contains | Depends on |
|-------|----------|------------|
| Presentation | `*_page.dart`, `*_view.dart`, widgets | Bloc/Cubit |
| Business | Bloc/Cubit | Repositories |
| Data | repositories, API/DTOs | Dio / storage |

## Folder layout (per feature)

```text
lib/features/<name>/
  data/
    <name>_repository.dart
    models/          # optional DTOs
  presentation/
    <name>_page.dart   # BlocProvider
    <name>_view.dart   # BlocBuilder / Listener
    bloc/              # or cubit/
      <name>_bloc.dart
      <name>_event.dart
      <name>_state.dart
```

## Page / View

- **Page**: creates `BlocProvider`, no UI markup beyond providing bloc
- **View**: `BlocBuilder` / `BlocListener` / `BlocConsumer` only
- Callbacks: `context.read<XBloc>().add(...)` — never `watch` outside `build`

## Events & states

- Prefer **sealed** event/state hierarchies + Dart 3 `switch`
- Extend `Equatable`; put fields in `props`
- Event naming: `Subject` + `Noun` + `VerbPastTense` (e.g. `LoginFormSubmitted`)
- Loading flows: `Initial` → `InProgress` → `Success` | `Failure` **or** single state + `status` enum

## Cubit vs Bloc

- **Cubit**: simple UI-driven state (toggles, counters, form field holds)
- **Bloc**: multi-step / event-driven (auth submit, lists with refresh/retry)

## Testing

- Use `blocTest` from `bloc_test`, mocks via `mocktail`
- Mirror `lib/` under `test/`

## Do not

- Put networking or token storage inside widgets
- Emit after async gap without checking `emit.isDone` / cancellation where needed
- Import presentation widgets into data layer
