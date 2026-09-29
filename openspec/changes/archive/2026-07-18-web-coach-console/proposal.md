## Why

Mobile уже даёт тренеру полный MVP. Нужен **desktop-канал** к тому же Nest API: удобнее вести слоты, учеников, планы и lifecycle на большом экране. Фаза 7 — первый web-клиент, без новых доменных фич.

## What Changes

- Создать директорию **`web_app/`** в корне репо (рядом с `app/` и `backend/`) — Next.js (App Router) + TypeScript.
- Тонкая **консоль тренера**: login → shell → экраны поверх существующего API (связи, слоты, занятия + lifecycle/история, теги, планы).
- Клиентский HTTP-слой (fetch/axios), хранение сессии, RU UI.
- При необходимости минимальный backend-тюнинг для браузера (**CORS**) — **не ожидается** (уже включён).
- Краткие run-инструкции в README / docs.

## Non-goals

- Студенческий web-кабинет и публичный лендинг/маркетинг.
- Паритет 1:1 со всеми mobile-экранами и pixel-perfect design system (можно упрощённый UI; токены из `app/design` — ориентир, не обязательный полный порт).
- Новые API-фичи (billing, social, push, admin).
- Flutter Web вместо Next.js; перенос monorepo в `apps/web`.
- Shared `packages/` с zod-схемами (можно позже).

## Capabilities

### New Capabilities

- `web-app-bootstrap`: scaffold `web_app/` (Next.js), env к API, dev scripts, базовая структура.
- `web-coach-auth`: login / logout / session gate; доступ только для пользователя с ролью trainer (или trainer permissions).
- `web-coach-console`: authenticated UI — relationships, schedule slots, sessions (complete/cancel/no-show + history), tags, plans.

### Modified Capabilities

- _(нет)_ — Nest CORS уже разрешает browser-origin (`origin: true`); новых API-требований нет.

## Impact

- Новая папка `web_app/` (Node/Next зависимости).
- Возможна правка Nest `main.ts` (CORS) — точечно.
- Документы: `docs/architecture/repository.md` / README — путь `web_app` вместо целевого `apps/web`.
- Flutter и существующие API-контракты не ломаем.
