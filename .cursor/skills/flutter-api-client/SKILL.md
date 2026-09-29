---
name: flutter-api-client
description: >-
  Wire Dio HTTP client with JWT access/refresh tokens and flutter_secure_storage
  for Fitness Yoda NestJS API. Use when adding networking, interceptors, token
  refresh, or API repositories in app/fitness_app.
---

# Flutter API Client (Fitness Yoda)

## Dependencies

```bash
flutter pub add dio flutter_secure_storage
```

Optional later: `pretty_dio_logger` (dev-only logging).

## Responsibilities

| Piece | Role |
|-------|------|
| `ApiClient` | Shared `Dio` instance, baseUrl, JSON |
| `AuthInterceptor` | Attach `Authorization: Bearer <access>` |
| `TokenStorage` | Read/write access + refresh in secure storage |
| `TokenRefresher` | `POST /auth/refresh` once; queue parallel 401s |
| Feature repositories | Call paths; map JSON → models; throw typed failures |

## Backend contract (current)

Base URL (dev): `http://localhost:3000` (Android emulator often `10.0.2.2:3000`).

| Method | Path | Auth | Body / notes |
|--------|------|------|----------------|
| GET | `/health` | no | `{ status: ok }` |
| POST | `/auth/register` | no | `{ email, password, role: trainer\|student }` |
| POST | `/auth/login` | no | `{ email, password }` |
| POST | `/auth/refresh` | no | `{ refreshToken }` → new tokens |
| POST | `/auth/logout` | no | `{ refreshToken }` revoke |
| GET | `/users/me` | Bearer | needs permission `users:read_self` |

Auth success shape:

```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "user": {
    "id": "...",
    "email": "...",
    "roles": ["trainer"],
    "permissions": ["users:read_self"]
  }
}
```

## Token rules

1. On login/register/refresh: persist both tokens via `TokenStorage`
2. On each request: set Bearer access token
3. On **401** (except login/register/refresh): try refresh **once**; retry original
4. If refresh fails: clear storage; signal session expired (Cubit/Bloc / callback)
5. On logout: call API then clear storage (idempotent if refresh already dead)

## Layout suggestion

```text
lib/core/network/
  api_client.dart
  auth_interceptor.dart
  token_storage.dart
  api_exception.dart
```

## Do not

- Store tokens in `SharedPreferences` plaintext
- Put refresh logic inside every repository
- Hardcode production baseUrl without flavor/env
