## Why

Backend auth уже работает (register/login/refresh/logout/me). Следующий шаг roadmap — примитивный Flutter-клиент, чтобы закрыть вертикаль «можно залогиниться с телефона» и готовить почву под QR/занятия.

## What Changes

- Поднять зависимости в `app/fitness_app`: `flutter_bloc`, `equatable`, `go_router`, `dio`, `flutter_secure_storage`, `bloc_test`/`mocktail` (dev).
- Добавить core network: Dio client, token storage, auth interceptor + refresh.
- Добавить Auth Cubit/Bloc + repository под Nest API.
- Экраны: login, register (role trainer|student), home (профиль + logout).
- `go_router` с redirect по сессии.
- Базовый Material UI (без полировки дизайна).

## Non-goals

- Изменения Nest API / TypeORM / permissions model.
- QR-приглашения, календарь, занятия, push.
- Riverpod / сложный clean-arch starter (freezed, hive, get_it) — не тянем.
- Production flavors, CI mobile, store listing.
- Web / Next.js.

## Capabilities

### New Capabilities

- `mobile-app-shell`: Flutter app wiring (DI/providers, router, theme stub).
- `mobile-auth`: login/register/logout/session restore against existing API.
- `mobile-api-client`: Dio + secure tokens + refresh handling.

### Modified Capabilities

- (нет обязательных изменений backend specs; клиент потребляет существующий `user-auth`)

## Impact

- Код: `app/fitness_app/lib/**`, `pubspec.yaml`.
- Dev: нужен запущенный API на `localhost:3000` (эмулятор Android → `10.0.2.2:3000`).
- Skills: `flutter-bloc-feature`, `flutter-api-client`, `flutter-auth-shell`.
- Docs: `docs/mobile/tooling.md`, roadmap phase 2.
