## Why

Нужен рабочий фундамент API, чтобы дальше строить мобильный MVP. Сейчас `backend/` пустой, а без простой авторизации и расширяемой модели доступа нельзя безопасно добавлять занятия, QR и остальной домен из `docs/`.

## What Changes

- Поднять NestJS API в `backend/api` + PostgreSQL через Docker Compose.
- Добавить минимальный auth: регистрация, логин, refresh, текущий пользователь (`/me`).
- Ввести permission-based авторизацию: роли (`trainer`, `student`, `admin`) — только именованные наборы permissions; проверки в коде — по permissions.
- Зафиксировать health-check и базовую структуру модулей под рост продукта.
- Обновить корневой README с командами запуска API/БД.

## Non-goals

- Flutter / web UI (отдельные следующие changes).
- Email verification, reset password, OAuth, SMS, push, рефералы.
- QR-приглашения, календарь, занятия, планы, теги, биллинг, соцслой.
- Сложный admin UI для управления ролями (достаточно seed + API-ready модели).

## Capabilities

### New Capabilities

- `api-bootstrap`: каркас NestJS, конфиг, health, Postgres/Prisma, локальный запуск.
- `user-auth`: регистрация/логин/refresh/logout-семантика, JWT, профиль `/me`.
- `access-control`: permissions, роли как bundles, guards/decorators, seed ролей.

### Modified Capabilities

- (нет — `openspec/specs/` пуст)

## Impact

- Новые зависимости: NestJS, Prisma, PostgreSQL, JWT, bcrypt.
- Затронутые пути: `backend/`, `docker-compose.yml`, корневой `README.md`.
- Клиенты пока не меняются; контракт API станет опорой для `mvp-mobile-auth-shell`.
- Продуктовый контекст: `docs/roadmap/plan.md`, `docs/architecture/stack.md`, `docs/product/roles-and-features.md`.
