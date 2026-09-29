# Fitness Yoda — документация

Документация продукта, собранная с [Miro-доски](https://miro.com/app/board/uXjVPLnb8m8=/) и дополненная решениями по стеку и плану разработки.

Цель этих файлов — дать агенту (OpenSpec / Cursor) устойчивый контекст: **что строим**, **для кого**, **какой стек**, **какие доменные сущности и процессы**, **в каком порядке делать**.

Живая карта код ↔ спека ↔ архив для агента: [`.cursor/project/docs/map.md`](../.cursor/project/docs/map.md).

## Карта документов

| Раздел | Файл | Содержание |
|--------|------|------------|
| Продукт | [product/vision.md](product/vision.md) | Суть продукта, ценность, границы MVP |
| Роли и фичи | [product/roles-and-features.md](product/roles-and-features.md) | Тренер / студент, карта модулей |
| Домен | [domain/entities.md](domain/entities.md) | Сущности и связи (из DB Relations + процессов) |
| Процессы | [domain/processes.md](domain/processes.md) | Запись, подтверждение, история, события |
| Теги | [domain/tags.md](domain/tags.md) | Группировка людей и планов |
| Приглашения | [domain/invitations.md](domain/invitations.md) | QR / codec / онбординг |
| Биллинг | [domain/billing.md](domain/billing.md) | Ручной finance ledger (без эквайринга) |
| Social / privacy | [domain/social-privacy.md](domain/social-privacy.md) | Профили, discovery, отзывы |
| Стек | [architecture/stack.md](architecture/stack.md) | Flutter, Nest, TypeORM, Next |
| Mobile tooling | [mobile/tooling.md](mobile/tooling.md) | Bloc, skills, MCP |
| Репозиторий | [architecture/repository.md](architecture/repository.md) | Структура monorepo |
| Календарь | [architecture/calendar.md](architecture/calendar.md) | Календарь как ядро продукта |
| План | [roadmap/plan.md](roadmap/plan.md) | Фазы и порядок работ |
| Источник | [sources/miro.md](sources/miro.md) | Карта фреймов Miro |
| Design system | [design/design-system-status.md](design/design-system-status.md) | Статус DS |
| Макеты UI | [assets/](assets/) | PNG-концепты экранов |

## Текущее состояние репозитория

- `backend/api/` — NestJS API (auth, schedules, sessions, plans, tags, workouts, finance, social…)
- `app/fitness_app/` — Flutter mobile client (Bloc/Cubit)
- `web_app/` — Next.js консоль тренера
- `openspec/` — baseline specs + active/archived changes
- Dev: API `localhost:3001`, web `localhost:3000` (см. корневой README)

## Как использовать с OpenSpec

1. Держать `docs/` как source of truth по продукту.
2. В OpenSpec specs ссылаться на эти файлы (или переносить куски в `openspec/specs/`).
3. Каждую фичу начинать с change proposal → tasks → реализация; после archive — обновить `.cursor/project/docs/map.md`.

## Источник правды

При конфликте приоритет:

1. Явные решения в чате / OpenSpec change
2. `openspec/specs/`
3. Документы в `docs/`
4. [Miro-доска](https://miro.com/app/board/uXjVPLnb8m8=/)
