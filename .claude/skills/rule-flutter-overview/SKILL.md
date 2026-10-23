---
name: rule-flutter-overview
description: Fitness Yoda mobile conventions (Flutter + Bloc)
---
<!-- pipil-sync: из .cursor/rules/flutter-overview.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# Flutter (Fitness Yoda)

- State: **Bloc/Cubit only** (`flutter_bloc`). Do not introduce Riverpod/Provider as app state.
- Routing: `go_router` with auth redirects.
- HTTP: `dio` + `flutter_secure_storage` for tokens.
- App lives in `app/fitness_app/`.
- Prefer feature folders: `lib/features/<feature>/{data,domain,presentation}`.
- API base: NestJS at `http://localhost:3001` (dev); contracts in Postman/`docs`.
- Skills: `flutter-bloc-feature`, `flutter-api-client`, `flutter-auth-shell`.
