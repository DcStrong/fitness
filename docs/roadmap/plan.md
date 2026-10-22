# План действий (MVP + post-MVP)

Документ — рабочий roadmap. Работаем через **OpenSpec** (`/opsx-propose` → `/opsx-apply` → `/opsx-archive`).

## Принцип доставки (зафиксировано)

```text
Backend (базовый)  →  Flutter (примитив)  →  Web (позже)
```

Вертикальные срезы после фундамента: каждая фича = API + минимум mobile UI.  
Web не блокирует мобильный MVP.

## Решения (закрытые вопросы)

| Вопрос | Решение |
|--------|---------|
| Auth | Email + пароль. Logout с revoke refresh. Без email-verify, OAuth, SMS |
| Авторизация | **Permissions** + роли как наборы permissions (`trainer`, `student`, `admin`) |
| Persistence | **TypeORM** + PostgreSQL (Prisma убрана) |
| Mobile state | **Bloc/Cubit** + `go_router` + `dio` |
| Порядок клиентов | Сначала mobile, web в конце |
| Сложность v1 | Максимально просто; усиливаем по мере роста |

## Статус (обновлять после archive)

| Фаза | Change | Статус |
|------|--------|--------|
| 1 | `mvp-backend-auth-permissions` | ✅ archived `2026-07-17-mvp-backend-auth-permissions` |
| 1b | `migrate-prisma-to-typeorm` | ✅ archived `2026-07-17-migrate-prisma-to-typeorm` |
| 2 | `mvp-mobile-auth-shell` | ✅ archived `2026-07-17-mvp-mobile-auth-shell` |
| 3 | `invitations-qr` | ✅ archived `2026-07-17-invitations-qr` |
| 4 | `schedules-sessions` | ✅ archived `2026-07-18-schedules-sessions` |
| 5 | `session-lifecycle-history` | ✅ archived `2026-07-18-session-lifecycle-history` |
| 6 | `training-plans-tags` | ✅ archived `2026-07-18-training-plans-tags` |
| 7 | `web-coach-console` | ✅ archived `2026-07-18-web-coach-console` |
| 8 | `billing-stats` | ✅ archived `2026-07-18-billing-stats` |
| 9 | `social-privacy` | ✅ archived `2026-07-19-social-privacy` |

**Тонкий MVP (фазы 1–9) закрыт.** Schedule/coach UX (слои A–C), абонементы, workout program/progression и design волна A — закрыты (см. «Сделано после MVP»).

**СЕЙЧАС:** Roadmap v2 (см. ниже): этап 0 — рабочая база (CI, зелёные тесты), этап 1 — продуктовый разбор экранов. Продакшен — последним этапом.

**Handoff для агента после archive:** обновить эту таблицу / post-MVP очереди, предложить `/opsx-propose` для следующей строки со статусом «СЕЙЧАС».

## Hotfix вне OpenSpec

| Когда | Что | Где |
|-------|-----|-----|
| 2026-08-05 | CORS: Flutter web Dio шлёт `Cache-Control`/`Pragma`; без них Chrome preflight → «Нет связи с сервером» (macOS ок) | `backend/api/src/main.ts` → `allowedHeaders` включает `Cache-Control`, `Pragma` |

Не оформлялось отдельным change; при регрессии web-логина проверять CORS first.

## Фазы MVP

### Фаза 0–1 — Backend foundation + auth/permissions ✅

### Фаза 2 — Primitive Flutter auth client ✅

### Фаза 3 — QR-приглашения (mobile + API) ✅

OpenSpec: `invitations-qr` → archived `2026-07-17-invitations-qr`

### Фаза 4 — График и занятия ✅

OpenSpec: `schedules-sessions` → archived `2026-07-18-schedules-sessions`

### Фаза 5 — Lifecycle + история ✅

OpenSpec: `session-lifecycle-history` → archived `2026-07-18-session-lifecycle-history`

### Фаза 6 — Планы + теги ✅

OpenSpec: `training-plans-tags` → archived `2026-07-18-training-plans-tags`

### Фаза 7 — Web coach console ✅

OpenSpec: `web-coach-console` → archived `2026-07-18-web-coach-console`

### Фаза 8 — Финансовый учёт + статистика ✅

OpenSpec: `billing-stats` → archived `2026-07-18-billing-stats`

### Фаза 9 — Social + приватность ✅

OpenSpec: `social-privacy` → archived `2026-07-19-social-privacy`

## Сделано после MVP

| Change | Фокус | Статус |
|--------|--------|--------|
| `apply-fitness-yoda-design-system` | DS stages 1–6 (tokens, buttons, cards, shell, auth, home) | ✅ archived `2026-07-18-apply-fitness-yoda-design-system` |
| `home-daily-schedule` | Home daily schedule | ✅ archived `2026-07-19-home-daily-schedule` |
| `add-booking-requests` | Booking requests API + mobile | ✅ archived `2026-07-19-add-booking-requests` |
| `add-mobile-calendar-views` | Day/week/month calendar | ✅ archived `2026-07-21-add-mobile-calendar-views` |
| `add-trainer-availability` | Availability template / generate | ✅ archived `2026-07-21-add-trainer-availability` |
| `add-recurring-booking` | Recurring bookings API + mobile | ✅ archived `2026-08-04-add-recurring-booking` |
| `add-coach-book-at-time` | Book-at-time API | ✅ archived `2026-08-04-add-coach-book-at-time` |
| `add-coach-booking-ux` | Coach FAB / slot / empty-hour UX | ✅ archived `2026-08-05-add-coach-booking-ux` |
| `fix-recurring-session-calendar-ux` | Detail «Готово»/горизонт, cancel frees slots, archive, session sheet | ✅ archived `2026-08-08-fix-recurring-session-calendar-ux` |
| `improve-recurring-list-ux` | Recurring list UX | ✅ archived `2026-08-08-improve-recurring-list-ux` |
| `polish-mobile-design-system` | Волна A: шрифт, Fy-примитивы, debt cleanup | ✅ archived `2026-08-08-polish-mobile-design-system` |
| `add-session-packages` | Абонемент: лимит, «осталось N», debit на complete/no_show | ✅ archived `2026-08-16-add-session-packages` |
| `polish-schedule-calendar-ux` | Calendar polish | ✅ archived `2026-08-16-polish-schedule-calendar-ux` |
| `day-timeline-variable-hour-height` | Variable hour height timeline | ✅ archived `2026-08-16-day-timeline-variable-hour-height` |
| `fix-student-slot-request-window` | Student slot request window | ✅ archived `2026-08-18-fix-student-slot-request-window` |
| `structured-workout-templates` | Structured workout templates | ✅ archived `2026-08-18-structured-workout-templates` |
| `tag-library-and-exercise-assign` | Tag library / exercise assign | ✅ archived `2026-08-18-tag-library-and-exercise-assign` |
| `workout-assign-and-session-page` | Assign workouts + session page | ✅ archived `2026-08-18-workout-assign-and-session-page` |
| `workout-progress-and-student-hub` | Progress + student hub | ✅ archived `2026-08-18-workout-progress-and-student-hub` |
| `workout-program-and-progression` | Program on recurring + weight progression | ✅ archived `2026-08-21-workout-program-and-progression` |
| `polish-student-hub-session-tags-ui` | Student hub / session / tags UI polish | ✅ archived `2026-08-23-polish-student-hub-session-tags-ui` |

Источник статусов дизайн-долга: [docs/design/design-system-status.md](../design/design-system-status.md).  
Домен слоёв A/B/C: [docs/design/availability-recurring-booking.md](../design/availability-recurring-booking.md).

## Roadmap v2 (с 2026-10-22)

Приоритет: сначала продукт в «полноценном» состоянии и редизайн, продакшен — последним.
Полный аудит и план: [Fitness Yoda: аудит и план](https://claude.ai/artifact/Dwyc9S7zx5Bf64nUuTD9CA).

| Этап | Что | Статус |
|------|-----|--------|
| 0 | Рабочая база: lock-файлы, зелёные тесты, CI на PR | **СЕЙЧАС** |
| 1 | Продуктовый разбор: скриншоты всех экранов, сценарии, UX-проблемы, IA, финальный backlog | **СЕЙЧАС** |
| 2 | Редизайн: 2–3 концепта → выбор → дизайн-система v2 (светлая + тёмная) | очередь |
| 3 | Фичи в новом дизайне: уведомления, чат тренер↔ученик, статистика тренера, кошелёк v2, опыт ученика, группы, аккаунт/онбординг, рефералы | очередь |
| 4 | Перенос существующих экранов на дизайн-систему v2 | очередь |
| 5 | Продакшен: требования сторов, инфра/деплой, безопасность, бета, релиз | очередь |

Каждая фича этапа 3 — отдельный OpenSpec change. Web-консоль тренера заморожена (поддерживается в сборке).

## Post-MVP: Product (живой backlog)

| # | Change (рабочее имя) | Фокус | Статус |
|---|----------------------|--------|--------|
| 0 | `add-coach-student-chat` | Чат 1:1 тренер↔ученик (текст, фото, непрочитанные, push) | очередь |
| 1 | `add-notifications` | In-app (± email); позже push — ближайшее занятие, пакет, заявки, lifecycle | очередь |
| 2 | `trainer-stats-dashboard` | Занятость / доход / no-show / остатки пакетов (экран-потребитель для волны D) | очередь |
| 3 | `billing-invoices-wallet` | Глубже ручного биллинга: счёт/баланс ученика; **не** эквайринг | очередь |
| 4 | `group-sessions` | `capacity > 1`, участники, UI групповой записи | очередь |
| 5 | `referrals` | Реферальная механика | очередь |

Не смешивать product-change с design-волной в одном apply без явной причины.

## Post-MVP: Design polish

Очередь волн из отложенного дизайн-пака. Не смешивать волны в один apply без необходимости.

| Волна | Change | Фокус | Статус |
|-------|--------|--------|--------|
| **A** | `polish-mobile-design-system` | Шрифт, `FySecondaryButton`, `FyChip`, `showFyBottomSheet`, barrel, debt cleanup | ✅ archived `2026-08-08-polish-mobile-design-system` |
| **B** | `polish-mobile-shell-auth` | Custom top bar, auth décor / hero, motion (press / tabs / auth panel / calendar day) | ✅ archived `2026-08-21-polish-mobile-shell-auth` |
| **B+** | `polish-trainer-home-bento` | Trainer Home: week mini-calendar, stat chips, asymmetric bento | ✅ archived `2026-09-29-polish-trainer-home-bento` |
| **B++** | `polish-trainer-home-bento-visual` | Visual fidelity к mock-home-c (stat cards, timeline, week chart, Перейти) | ✅ archived `2026-09-29-polish-trainer-home-bento-visual` |
| C | _(TBD)_ | Dark theme по токенам + `ThemeMode` | поглощена редизайном v2 (Roadmap v2, этап 2) |
| D | — | Parked до экрана-потребителя: metric gauge, pagination dots, twin cards, floating icon buttons, section badge `01` | parked |

### Волна A — инфраструктура DS ✅

- Plus Jakarta Sans (фирменный шрифт; Manrope не берём)
- `FySecondaryButton`, `FyChip`, `showFyBottomSheet`
- Barrel export `core/widgets`
- Замена сырых `Card` / `OutlinedButton` / локальных chips в schedule/recurring

### Волна B — auth/shell polish ✅

- `FyTopBar`; auth hero asset + mint décor / wave; press scale; shell tab fade+slide; auth panel entrance; calendar day switch

### Волна C — theme completeness (поглощена редизайном v2)

- `AppTheme.dark()` по токенам; достижимый `ThemeMode`

### Волна D — parked

Ждут продуктового экрана (напр. stats dashboard) или стабилизации форм book/free-time.

## Очередь OpenSpec changes (MVP)

| # | Change | Фокус | Статус |
|---|--------|--------|--------|
| 1 | `mvp-backend-auth-permissions` | API auth + RBAC | ✅ |
| 1b | `migrate-prisma-to-typeorm` | Prisma → TypeORM | ✅ |
| 2 | `mvp-mobile-auth-shell` | Flutter login/register/me | ✅ |
| 3 | `invitations-qr` | QR invite | ✅ |
| 4 | `schedules-sessions` | График + запись | ✅ |
| 5 | `session-lifecycle-history` | Complete/cancel + history | ✅ |
| 6 | `training-plans-tags` | Планы + теги | ✅ |
| 7 | `web-coach-console` | Next.js | ✅ |
| 8 | `billing-stats` | Финансовый учёт / статистика | ✅ |
| 9 | `social-privacy` | Лента / отзывы / приватность | ✅ |

## Definition of Done — тонкий MVP

1. Регистрация/логин ✅
2. QR-приглашение и связь тренер↔ученик ✅
3. Запись на занятие (book) + lifecycle complete/cancel/no_show + history ✅
4. Простой план (опционально тег) ✅

## Ссылки

- Продукт: [docs/product/vision.md](../product/vision.md)
- Стек: [docs/architecture/stack.md](../architecture/stack.md)
- Домен: [docs/domain/entities.md](../domain/entities.md)
- Финансовый учёт: [docs/domain/billing.md](../domain/billing.md)
- Социальный слой: [docs/domain/social-privacy.md](../domain/social-privacy.md)
- Приглашения: [docs/domain/invitations.md](../domain/invitations.md)
- Календарь (архитектура): [docs/architecture/calendar.md](../architecture/calendar.md)
- Дизайн-система (статус): [docs/design/design-system-status.md](../design/design-system-status.md)
- Доступность / recurring / Слой C: [docs/design/availability-recurring-booking.md](../design/availability-recurring-booking.md)
- Mobile tooling: [docs/mobile/tooling.md](../mobile/tooling.md)
