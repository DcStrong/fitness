## Context

Fitness Yoda стартует с пустого `backend/` и Flutter scaffold. Продуктовый контекст уже в `docs/`; первый технический шаг — тонкий API, на который сядет мобильный клиент.

Платформенные правила NestJS лежат в `.cursor/platform` (modules, DTO, middleware → guard → Authority). Этот change задаёт минимальный каркас, совместимый с этими правилами, без переноса всей «толстой» платформы разом.

## Goals / Non-Goals

**Goals:**

- Поднять NestJS + Prisma + PostgreSQL локально.
- Дать register / login / refresh / logout / me на email+password.
- Заложить RBAC через permissions; роли — seedable bundles (`trainer`, `student`, `admin`).
- Сделать проверки доступа по permission codes.

**Non-Goals:**

- Mobile/web UI.
- Email verify, OAuth, SMS, password reset flows.
- Управление ролями через полноценный admin UI.
- Доменные модули (sessions, invites, plans).

## Decisions

### 1. Layout: `backend/api`

- NestJS приложение в `backend/api`.
- Корневой `docker-compose.yml` с сервисом `postgres`.
- Альтернатива monorepo `apps/` отложена — меньше движения файлов сейчас; перенос возможен позже (`docs/architecture/repository.md`).

### 2. Identity: email + password (зафиксировано)

- Идентификатор: **email-only** (unique). Поле в API/БД: `email`. Username/phone — не в этом change.
- DTO: валидация формата email.
- Пароль: bcrypt hash, min length в DTO validation (например 8).
- Нет verify email / magic link.

### 3. Tokens: JWT access + refresh

- Access JWT короткий TTL; payload: `sub` (userId), `permissions[]` (или тонкий token + load permissions из БД на request — см. ниже).
- Refresh token: opaque random string, хранится hashed в БД (`refresh_tokens`).
- **Logout обязателен:** `POST /auth/logout` отзывает (invalidate) текущий refresh token.
- **Выбор для MVP:** access token содержит `sub` + `roleIds`/`permissions` snapshot; при смене ролей пользователь перелогинивается / refresh пересобирает claims. Проще для mobile.

### 4. AuthZ model: permissions first

```text
User  M2M  Role  M2M  Permission
```

- `Permission.code` — стабильный строковый код (`users:read_self`, `users:register`, позже `sessions:create`).
- `Role.slug` — `trainer` | `student` | `admin` (и любые будущие).
- Guards/decorators проверяют `@RequirePermissions('...')`, **не** `@Roles('trainer')`.
- Seed назначает permissions ролям. Admin seed — только через seed/script, не через public register.

### 5. Minimal permission set for this change

| Code | Назначение | Роли (seed) |
|------|------------|-------------|
| `users:read_self` | GET /me | trainer, student, admin |
| `auth:refresh` | refresh (или public with valid refresh) | — |
| `admin:access` | маркер админ-зоны (заглушка) | admin |

Публичные: `POST /auth/register`, `POST /auth/login`.  
С валидным refresh (или access — по реализации): `POST /auth/refresh`, `POST /auth/logout`.  
Защищённые: `GET /users/me` (нужен `users:read_self`).

Новые доменные permissions добавим в следующих changes без смены механизма.

### 6. Nest modules

- `AppModule`, `HealthModule` / controller
- `PrismaModule`
- `AuthModule` (register, login, refresh, logout)
- `UsersModule` (`/me`)
- `AccessControlModule` (permissions guard, seed helpers)

Согласовать с `.cursor` правилами: controller → service → repository; DTO validation.

### 7. Config

- `.env.example`: `DATABASE_URL`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, TTL.
- Не коммитить секреты.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Permissions в JWT устаревают после смены ролей | Короткий access TTL; refresh перечитывает БД |
| Over-engineering RBAC | Только 3 роли + 1–2 permission codes сейчас |
| Platform rules vs greenfield Nest | Следовать духу rules, не копировать всю legacy-платформу |
| Один user — несколько ролей | Модель M2M уже позволяет; register даёт одну роль |

## Migration Plan

1. Добавить Compose + Prisma schema + initial migration.
2. Seed roles/permissions (+ optional admin user via env).
3. Поднять API, проверить `/health`, register, login, me, refresh, logout.
4. Rollback: down Compose volumes; миграции вперёд-only для local MVP.

## Decisions locked (was Open Questions)

1. **Email-only** — идентификатор пользователя = email.
2. **Logout сразу** — `POST /auth/logout` с revoke refresh token.

## Still open (не блокирует apply)

1. Один пользователь — несколько ролей в будущем UI или одна активная? Модель БД уже M2M.
