## Why

Целевой ORM в `docs/architecture/stack.md` и платформенных skills — **TypeORM**, а auth MVP сейчас на Prisma. Нужно выровнять persistence до роста домена (sessions, invites), иначе придётся мигрировать больше сущностей позже.

## What Changes

- Заменить Prisma на TypeORM (`@nestjs/typeorm`) в `backend/api`.
- Перенести сущности: User, Role, Permission, UserRole, RolePermission, RefreshToken.
- Перенести миграции и seed (роли/permissions/optional admin) на TypeORM.
- Переписать `PrismaService` / репозиторные вызовы в Auth (и связанных модулях) на TypeORM repositories / DataSource.
- Удалить Prisma (`prisma/`, зависимости, npm scripts).
- Сохранить внешний API-контракт auth без изменений поведения.

## Non-goals

- Редизайн auth/permissions или новых эндпоинтов.
- Flutter / web.
- Доменные модули (QR, sessions, plans).
- Смена PostgreSQL или Docker-схемы БД (только способ доступа к ней).

## Capabilities

### New Capabilities

- `persistence-typeorm`: TypeORM DataSource, entities, migrations, seed, Nest integration.

### Modified Capabilities

- `user-auth`: та же семантика register/login/refresh/logout/me, но через TypeORM storage.
- `access-control`: те же permission checks; загрузка ролей/permissions через TypeORM.
- `api-bootstrap`: health/env/compose остаются; bootstrap persistence переезжает с Prisma на TypeORM.

## Impact

- `backend/api`: зависимости, `src/**`, удаление `prisma/`.
- Dev workflow: `typeorm migration:*` / seed вместо `prisma migrate/seed`.
- Клиенты не затрагиваются при сохранении HTTP-контракта.
- После cutover: накатить TypeORM migrations + seed на **уже пустую** локальную БД (volume пересоздан; migrate-in-place не требуется).
