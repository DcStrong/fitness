# Технологический стек

## Решение

| Слой | Технология | Комментарий |
|------|------------|-------------|
| Mobile | **Flutter** (Dart) | iOS + Android; в репо уже есть `app/fitness_app` |
| Web | **Next.js (React) + TypeScript** | Рекомендация по умолчанию |
| API | **NestJS + TypeScript** | Модульный бэкенд |
| БД | **PostgreSQL** | Реляционная модель (занятия, связи, теги) |
| ORM | **TypeORM** (in use) | Entities + migrations в `backend/api/src/database` |
| Auth | JWT (access + refresh) | Позже: OAuth / phone OTP |
| Realtime / push | TBD | WebSocket или FCM/APNs для уведомлений |
| Инфра | Docker Compose (local) | `api` + `postgres` (+ optional `redis`) |

## Почему такой выбор

### Flutter для мобилки

- Один код для iOS/Android.
- QR-сканер, deep links, offline-friendly UX — сильная сторона.
- Уже начат scaffold в репозитории.

### NestJS + PostgreSQL + TypeScript

- Совпадает с твоим выбором.
- Чётко ложится на доменные модули: `auth`, `users`, `invitations`, `schedules`, `sessions`, `plans`, `tags`, `billing`, `notifications`.
- PostgreSQL хорошо держит связи Coach/Student/Plan/Session и soft delete.

### Web: Next.js, а не Vue/Nuxt (рекомендация)

Можно взять любой популярный фреймворк. **Предлагаю Next.js**, потому что:

- один язык с NestJS (TypeScript);
- проще шарить DTO/типы через `packages/shared`;
- удобен для SSR лендинга + app shell тренера на desktop.

Если команда/предпочтение — Vue: **Nuxt 3** тоже ок, API от этого не меняется.

Альтернатива «только Flutter Web» возможна, но для сложного desktop-UX тренера (календарь, таблицы) отдельный web обычно удобнее.

## Архитектура высокого уровня

```text
┌──────────────┐   ┌──────────────┐
│ Flutter App  │   │ Next.js Web  │
│ (mobile)     │   │ (web)        │
└──────┬───────┘   └──────┬───────┘
       │  HTTPS/JSON      │
       └────────┬─────────┘
                ▼
        ┌───────────────┐
        │  NestJS API   │
        └───────┬───────┘
                ▼
        ┌───────────────┐
        │  PostgreSQL   │
        └───────────────┘
```

## Модули API (черновик)

| Модуль NestJS | Ответственность |
|---------------|-----------------|
| `AuthModule` | регистрация, логин, refresh, роли |
| `UsersModule` | профиль, приватность |
| `InvitationsModule` | QR token create/accept/revoke |
| `SchedulesModule` | график, слоты, gym |
| `SessionsModule` | запись, статусы, подтверждение |
| `PlansModule` | планы тренировок, назначения |
| `TagsModule` | теги людей и планов |
| `BillingModule` | фактуры, кошелёк (P2) |
| `NotificationsModule` | outbox / push / in-app |
| `SocialModule` | лента, отзывы, рейтинг (P3) |

## Клиентские библиотеки (ориентир)

### Flutter

- state: **`flutter_bloc` / `bloc`** (зафиксировано; не Riverpod)
- routing: `go_router`
- network: `dio`
- QR: `mobile_scanner` / `qr_flutter`
- local storage: `flutter_secure_storage`

### Next.js

- App Router
- TanStack Query
- UI: на выбор (не фиксируем дизайн-систему здесь)
- auth cookies / token storage по security best practices

## Дизайн / палитра

На доске есть фрейм «Палитра для темной темы» (подбор цветов: тёмный / peach / серый / зелёный). Точные hex нужно снять с макета отдельно; пока фиксируем:

- поддержка **тёмной темы** заложена;
- бренд-акцент — не финализирован в docs (взять из изображения Miro на этапе UI).

## Что сознательно не фиксируем сейчас

- Конкретный хостинг (Vercel / Fly / VPS).
- Платёжный провайдер.
- Аналитика / Sentry — подключить на этапе infra.
