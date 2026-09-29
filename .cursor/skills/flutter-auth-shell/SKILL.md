---
name: flutter-auth-shell
description: >-
  Build Fitness Yoda auth shell: go_router redirects, login/register screens,
  AuthBloc/Cubit, and /users/me bootstrap. Use when implementing mobile auth MVP
  or wiring session-aware navigation in app/fitness_app.
---

# Flutter Auth Shell (Fitness Yoda)

Use with skills `flutter-bloc-feature` and `flutter-api-client`.

## Goal

Minimal mobile auth against Nest API:

1. Register (`trainer` | `student`) or Login
2. Persist tokens
3. Load `/users/me`
4. Redirect unauthenticated users to login
5. Logout clears session

## Routes (`go_router`)

Suggested paths:

| Path | Screen |
|------|--------|
| `/login` | Login |
| `/register` | Register (role picker) |
| `/home` | Placeholder home showing email/roles |
| `/splash` | optional bootstrap while reading tokens |

`redirect`:

- no access token → `/login` (allow `/login`, `/register`)
- has token and going to `/login` or `/register` → `/home`
- after failed refresh → `/login`

## Auth state (prefer Cubit or small Bloc)

Suggested states:

- `AuthUnknown` — app start, reading storage
- `AuthUnauthenticated`
- `AuthAuthenticated({ user })`
- `AuthFailure({ message })` (optional, or surface via UI listener)

Events / methods:

- `AppStarted` — read tokens; if present call `/users/me`
- `LoginSubmitted(email, password)`
- `RegisterSubmitted(email, password, role)`
- `LogoutRequested`

## Screens

- Login: email + password ≥ 8; button → API; on success → `context.go('/home')`
- Register: email + password + role dropdown (`trainer`/`student` only)
- Home: show `user.email`, `roles`, `permissions`; logout button

Page/View split per `flutter-bloc-feature`.

## Wiring

```text
App
 └─ RepositoryProvider / DI for AuthRepository + TokenStorage
     └─ BlocProvider<AuthBloc|AuthCubit>
         └─ MaterialApp.router(routerConfig: goRouter)
```

`goRouter` should read auth status from a `Listenable` (e.g. `AuthCubit` stream → `GoRouterRefreshStream`) so redirects re-run on login/logout.

## Out of scope (this skill)

- QR invite accept
- Push notifications
- Biometric unlock
- Email verification (API has none)
