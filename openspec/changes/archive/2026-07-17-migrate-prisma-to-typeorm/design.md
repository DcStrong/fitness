## Context

Auth MVP (`mvp-backend-auth-permissions`) работает на Prisma. Целевой стек и `.cursor/platform` skills ориентированы на TypeORM (entities, repositories, migrations). Миграция сейчас дешевле, чем после появления sessions/invites.

**Локальная БД пересоздана и сейчас полностью пустая** — можно сразу выпилить Prisma и накатить TypeORM migrations + seed с нуля, без migrate-in-place поверх Prisma-схемы.

## Goals / Non-Goals

**Goals:**

- Полностью заменить Prisma на TypeORM в `backend/api`.
- Сохранить HTTP-поведение auth/RBAC и e2e покрытие.
- Выровнять структуру под platform patterns: `database/entity`, repositories, migrations.

**Non-Goals:**

- Новые фичи продукта.
- Рефакторинг всего API под `#module/*` layout (можно частично, без блокировки cutover).
- Zero-downtime prod migration (локальный/ранний этап — допустим recreate DB).

## Decisions

### 1. Stack packages

- `@nestjs/typeorm`, `typeorm`, `pg`
- Удалить `@prisma/client`, `prisma`, папку `prisma/`

### 2. Connection config

- Оставить `DATABASE_URL` как primary (уже в `.env`).
- Альтернативно собирать URL из `DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USERNAME` / `DB_PASSWORD` если URL отсутствует.
- `TypeOrmModule.forRootAsync` + `autoLoadEntities: true` (или явный entities list).
- `synchronize: false` всегда; схема только миграциями.

### 3. Entities (parity with Prisma models)

| Entity | Notes |
|--------|-------|
| `User` | `email` unique, `passwordHash`, M2M roles |
| `Role` | `slug` unique |
| `Permission` | `code` unique |
| `UserRole` | composite PK userId+roleId |
| `RolePermission` | composite PK roleId+permissionId |
| `RefreshToken` | hashed token, expiresAt, revokedAt |

Следовать naming `snake_case` columns через `@Column({ name })` / naming strategy — как сейчас в Prisma `@@map`.

### 4. Repository style

- По platform: injectable `*Repository` wrapping DataSource/`Repository<Entity>`, сервисы не импортируют entity напрямую где возможно.
- Для MVP cutover допустим тонкий слой: AuthService → UserRepository / RefreshTokenRepository.

### 5. Migrations & seed

- TypeORM migrations в `src/database/migrations` (или `database/migrations` — зафиксировать одно место).
- Seed script (ts-node / nest command) с той же семантикой, что `prisma/seed.ts`.
- npm scripts: `typeorm:migration:run`, `typeorm:migration:generate`, `db:seed`.
- Local cutover recommendation: `docker compose down -v` (если ок потерять dev data) → migrate → seed. Либо drop prisma `_prisma_migrations` и применить TypeORM init migration на совместимую схему.

### 6. Cutover strategy (local) — БД пустая

Локальный PostgreSQL **уже пересоздан, данных нет**. Стратегия упрощается:

1. Добавить TypeORM (entities, repos, DataSource).
2. Переписать AuthService с Prisma на TypeORM.
3. Initial TypeORM migration + seed на пустую БД.
4. Удалить Prisma (`prisma/`, зависимости, scripts) в том же change — без dual-ORM окна.
5. e2e / smoke → обновить README и `docs/architecture/stack.md`.

Migrate-in-place поверх старых Prisma-таблиц **не нужен**.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Расхождение схемы Prisma vs TypeORM | Initial migration сверить с текущими таблицами; e2e auth |
| Потеря локальных данных | Документировать recreate; prod ещё нет |
| Partial dual-ORM window | Не мержить half-done; cutover в одном change |

## Migration Plan

1. Implement TypeORM module + entities + repos.
2. Switch AuthService off Prisma.
3. Migrations + seed.
4. Pass existing e2e/smoke.
5. Remove Prisma artifacts.
6. Update `docs/architecture/stack.md` row to «TypeORM (in use)».

## Open Questions

(нет — локальная БД пустая, recreate уже сделан)
