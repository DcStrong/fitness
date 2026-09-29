# Структура репозитория

## Сейчас

```text
fitness/
├── app/
│   └── fitness_app/     # Flutter
├── web_app/             # Next.js консоль тренера
├── backend/
│   └── api/             # NestJS
└── docs/
```

## Целевая структура (monorepo, позже)

```text
fitness/
├── apps/
│   ├── mobile/          # Flutter (переименовать/перенести fitness_app)
│   └── web/             # опционально перенос из web_app/
├── backend/
│   └── api/             # NestJS
├── packages/
│   └── shared/          # общие TS-типы/DTO/zod-схемы (web + api)
├── docs/
├── openspec/
├── docker-compose.yml
└── README.md
```

На текущем этапе web живёт в **`web_app/`** (рядом с `app/` и `backend/`), без обязательного переноса в `apps/web`.

## Соглашения

- API — единственный source of truth бизнес-правил.
- Клиенты (Flutter / Next) — тонкие: UI + вызовы API.
- Документация продукта живёт в `docs/`; OpenSpec specs — в `openspec/` и ссылаются сюда.
- Миграции БД — только через Prisma (или выбранный ORM), без ручных «тихонятных» правок в prod.

## Окружения

| Env | Назначение |
|-----|------------|
| `local` | docker-compose postgres + nest watch + flutter / next dev |
| `staging` | демо для проверки сценариев |
| `production` | бой |

## README корневой

После bootstrap корневой `README.md` должен кратко отвечать:

1. что за продукт (ссылка на `docs/product/vision.md`);
2. как поднять API + БД;
3. как запустить mobile / web;
4. где лежит план (`docs/roadmap/plan.md`).
