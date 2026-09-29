## 1. Bootstrap API & database

- [x] 1.1 Scaffold NestJS app in `backend/api` (TypeScript, basic module layout)
- [x] 1.2 Add Prisma, JWT, bcrypt, validation dependencies
- [x] 1.3 Create root `docker-compose.yml` with PostgreSQL and document ports/env
- [x] 1.4 Add `.env.example` (`DATABASE_URL`, JWT secrets, TTLs)
- [x] 1.5 Implement `GET /health` returning `{ status: "ok" }`
- [x] 1.6 Update root `README.md` with how to start DB + API

## 2. Data model & seed

- [x] 2.1 Prisma models: User, Role, Permission, UserRole, RolePermission, RefreshToken
- [x] 2.2 Create and apply initial migration
- [x] 2.3 Seed permissions (`users:read_self`, `admin:access`) and roles `trainer` / `student` / `admin`
- [x] 2.4 Optional seed admin user from env (not via public register)

## 3. Auth endpoints

- [x] 3.1 `POST /auth/register` — email + password + role (`trainer`|`student` only); validate email format; return tokens + profile
- [x] 3.2 `POST /auth/login` — email + password; return tokens + profile + permissions
- [x] 3.3 `POST /auth/refresh` — rotate/issue access from valid refresh; reject invalid
- [x] 3.4 `POST /auth/logout` — revoke refresh token (required)
- [x] 3.5 Hash passwords with bcrypt; never store plaintext

## 4. Access control & /me

- [x] 4.1 JWT middleware/guard attaching user + effective permissions to request
- [x] 4.2 `@RequirePermissions(...)` (or equivalent) decorator + guard — deny with 403 when missing
- [x] 4.3 `GET /users/me` (or `/auth/me`) protected by `users:read_self`
- [x] 4.4 Ensure business checks use permission codes, not role slug comparisons

## 5. Verification

- [x] 5.1 Manual smoke: health → register trainer → login → me → refresh → logout
- [x] 5.2 Manual smoke: register student; confirm admin self-register rejected
- [x] 5.3 Add minimal unit or e2e tests for register/login/me permission happy-path (optional but preferred)
