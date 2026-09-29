## 1. Project setup

- [x] 1.1 Add deps to `app/fitness_app`: flutter_bloc, equatable, go_router, dio, flutter_secure_storage; dev: bloc_test, mocktail
- [x] 1.2 Create folder layout `lib/app`, `lib/core`, `lib/features/auth`
- [x] 1.3 Add `API_BASE_URL` via dart-define with documented defaults (localhost / 10.0.2.2)

## 2. API client

- [x] 2.1 Implement `TokenStorage` (secure access + refresh)
- [x] 2.2 Implement `ApiClient` (Dio + baseUrl + JSON)
- [x] 2.3 Implement auth interceptor (Bearer + single-flight refresh on 401)
- [x] 2.4 Implement `AuthRepository` (register/login/refresh/logout/me)

## 3. Auth state & routing

- [x] 3.1 Implement `AuthCubit` (or AuthBloc): appStarted, login, register, logout, session restore
- [x] 3.2 Wire `go_router` with redirects + refresh listenable from auth state
- [x] 3.3 Replace root `main.dart` / `MaterialApp` with providers + `MaterialApp.router`

## 4. Screens

- [x] 4.1 Login page/view (email, password, error, submit)
- [x] 4.2 Register page/view (email, password, role trainer|student, submit)
- [x] 4.3 Home page/view (email, roles/permissions, logout)
- [x] 4.4 Russian UI copy for MVP labels/errors

## 5. Verification

- [x] 5.1 Manual smoke vs local API: register → me on home → logout → login
- [x] 5.2 Manual smoke: app restart restores session when tokens valid
- [x] 5.3 Optional: cubit unit test for login success/failure with mocked repository
