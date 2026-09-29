## Context

Backend auth MVP готов. Mobile app — Flutter scaffold в `app/fitness_app`. Зафиксированы Bloc, go_router, dio, secure storage (`docs/mobile/tooling.md` + project skills).

## Goals / Non-Goals

**Goals:**

- Рабочий auth shell: register/login/logout + session restore + home stub.
- Переиспользуемый Dio client с refresh.
- Навигация с auth redirects.

**Non-Goals:**

- Полный UI kit / тёмная тема из Miro.
- QR, занятия, сложный DI (get_it), freezed.
- Изменения API.

## Decisions

### 1. State: AuthCubit (or thin AuthBloc)

Для MVP достаточно **AuthCubit** (меньше boilerplate). Если понадобятся transformers — можно AuthBloc; в tasks допускается Cubit.

States: `unknown` | `unauthenticated` | `authenticated(user)` (+ failure message via listener/snackbar).

### 2. Structure

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
  core/
    network/   # ApiClient, interceptors, TokenStorage
    config/    # baseUrl
  features/
    auth/
      data/auth_repository.dart
      presentation/
        cubit/
        login/
        register/
        home/
```

Align with `flutter-bloc-feature` Page/View where practical (LoginPage/LoginView).

### 3. Base URL

- Compile-time or simple const/env: `--dart-define=API_BASE_URL=...`
- Defaults documented: iOS sim `http://localhost:3000`, Android emu `http://10.0.2.2:3000`

### 4. Token refresh

Single-flight refresh in interceptor; on failure clear storage + notify AuthCubit.

### 5. Localization

UI strings in Russian hardcoded for MVP (no l10n infra yet).

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Wrong baseUrl on device | dart-define + README note |
| Race on parallel 401s | queue/single refresh lock |
| Over-engineering folders | keep 1 feature `auth` only |

## Migration Plan

N/A (greenfield app code on scaffold).

## Open Questions

1. Default role on register UI: trainer preselected? **Recommendation:** trainer default, user can switch to student.
