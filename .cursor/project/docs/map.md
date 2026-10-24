# Fitness Yoda — живая карта (live-references)

Читать **до** широкого поиска по репозиторию. Обновлять при новом домене / feature и при `/opsx-archive`.

Запуск локально: корневой [README.md](../../../README.md).

## Активный change

| Change | Зачем |
|--------|--------|
| `add-coach-student-chat` | Чат тренер↔ученик: WebSocket + REST, системные сообщения о занятиях |
| `add-media-upload` | Загрузка картинок (`POST /media/images`, MinIO), портфолио до 5 фото |

## Домены API ↔ Flutter ↔ spec ↔ docs

### Auth / users

| API `backend/api/src/` | Flutter `lib/features/` | Specs | Docs |
|------------------------|-------------------------|-------|------|
| `auth`, `access-control`, `users` | `auth` | `user-auth`, `access-control`, `mobile-auth`, `mobile-api-client`, `mobile-app-shell` | `docs/product/roles-and-features.md` |

### Календарь и запись

| API | Flutter | Specs | Docs |
|-----|---------|-------|------|
| `schedules`, `calendar` | `schedule`, `home` | `schedules-api`, `calendar-domain`, `mobile-schedule-booking`, `mobile-availability`, `mobile-calendar-views`, `mobile-home-dashboard`, `mobile-coach-booking` | `docs/architecture/calendar.md`, `docs/domain/processes.md` |
| `sessions` | `schedule`, `home`, `session_workout` | `sessions-api`, `session-lifecycle`, `session-history`, `mobile-session-lifecycle` | `docs/domain/entities.md`, `docs/domain/processes.md` |
| `booking-requests` | `booking_requests` | `booking-requests-api` | `docs/domain/processes.md` |
| `recurring-bookings` | `schedule` | `recurring-bookings-api`, `mobile-recurring-booking` | `docs/design/availability-recurring-booking.md` |
| `session-packages` | `session_packages` | `session-packages-api`, `mobile-session-packages` | — |

### Тренировки

| API | Flutter | Specs | Docs |
|-----|---------|-------|------|
| `plans` | `plans` | `plans-api`, `workout-assignments-api`, `mobile-workout-templates`, `mobile-plans-tags` | `docs/domain/entities.md` |
| `exercises` | `plans`, `session_workout` | `exercises-api`, `exercise-visibility-api`, `mobile-exercise-library` | — |
| `tags` | `plans`, `student_hub` | `tags-api`, `mobile-tag-hub`, `mobile-plans-tags` | `docs/domain/tags.md` |
| `workout-programs` | `workout_program` | `workout-programs-api`, `mobile-workout-program` | — |
| `progress` | `student_hub`, `session_workout` | `workout-progress-api`, `mobile-workout-progress`, `mobile-student-hub`, `mobile-session-workout` | — |

### Finance

| API | Flutter | Specs | Docs |
|-----|---------|-------|------|
| `billing` (routes `/finance`) | `finance` | `finance-ledger`, `finance-stats-api`, `session-finance`, `mobile-finance`, `web-finance` | `docs/domain/billing.md` |

### Social / invitations

| API | Flutter | Specs | Docs |
|-----|---------|-------|------|
| `invitations` | `invitations` | `invitations-api`, `mobile-invitations`, `coach-student-link` | `docs/domain/invitations.md` |
| `social` (routes `/profiles`) | `social` | `profile-privacy`, `trainer-discovery`, `trainer-portfolio`, `session-reviews`, `mobile-social`, `web-social` | `docs/domain/social-privacy.md` |
| `gyms` (routes `/profiles/me/gyms`, `/gyms/suggestions`), фильтры в `social` | `social` | `trainer-gyms-api`, `trainer-discovery` | `docs/domain/gyms.md` |

### Чат

| API | Flutter | Specs | Docs |
|-----|---------|-------|------|
| `chat` (routes `/chats`, socket.io `/chat`) | `chats` | `chat-api`, `mobile-chat` (в `openspec/changes/add-coach-student-chat`) | — |

### Web (Next)

| Path | Specs | Notes |
|------|-------|-------|
| `web_app/` | `web-app-bootstrap`, `web-coach-auth`, `web-coach-console`, `web-finance`, `web-social` | Консоль тренера → API `:3001` |

### Инфра / DS

| Path | Specs | Docs |
|------|-------|------|
| `backend/api/src/database`, `health` | `api-bootstrap`, `persistence-typeorm` | `docs/architecture/stack.md`, `docs/architecture/repository.md` |
| `app/design/` | `mobile-design-system` | `docs/design/design-system-status.md`, `docs/mobile/tooling.md` |

## Архив changes (одна строка)

Читать `openspec/changes/archive/<folder>/proposal.md` или `design.md` только по имени ниже.

| Folder | Зачем |
|--------|--------|
| `2026-07-17-mvp-backend-auth-permissions` | Nest auth + permissions |
| `2026-07-17-migrate-prisma-to-typeorm` | Prisma → TypeORM |
| `2026-07-17-mvp-mobile-auth-shell` | Flutter login/register shell |
| `2026-07-17-invitations-qr` | QR trainer↔student |
| `2026-07-18-schedules-sessions` | Calendar slots + sessions API |
| `2026-07-18-session-lifecycle-history` | complete/cancel/no-show + history |
| `2026-07-18-training-plans-tags` | Training plans + tags |
| `2026-07-18-billing-stats` | Manual finance ledger |
| `2026-07-18-web-coach-console` | Next.js trainer console |
| `2026-07-18-apply-fitness-yoda-design-system` | Design pack → Flutter |
| `2026-07-19-add-booking-requests` | Student requests before session |
| `2026-07-19-home-daily-schedule` | Home = today’s schedule |
| `2026-07-19-social-privacy` | Profiles, discovery, reviews |
| `2026-07-21-add-trainer-availability` | Weekly availability → open slots |
| `2026-07-21-add-mobile-calendar-views` | Day/week/month calendar UX |
| `2026-08-04-add-coach-book-at-time` | Book at arbitrary time (API) |
| `2026-08-04-add-recurring-booking` | Recurring student schedule |
| `2026-08-05-add-coach-booking-ux` | Flutter booking UX |
| `2026-08-08-fix-recurring-session-calendar-ux` | Recurring detail/cancel/calendar fixes |
| `2026-08-08-improve-recurring-list-ux` | Recurring list findability |
| `2026-08-08-polish-mobile-design-system` | DS wave A |
| `2026-08-16-add-session-packages` | N-session packages |
| `2026-08-16-polish-schedule-calendar-ux` | Schedule UX polish |
| `2026-08-16-day-timeline-variable-hour-height` | Variable hour row height |
| `2026-08-18-fix-student-slot-request-window` | Hide slots past decision window |
| `2026-08-18-structured-workout-templates` | Exercise library + structured plans |
| `2026-08-18-tag-library-and-exercise-assign` | Tag hub + batch assign |
| `2026-08-18-workout-assign-and-session-page` | Assign copies + session workout page |
| `2026-08-18-workout-progress-and-student-hub` | Set logs, charts, student hub |
| `2026-08-21-workout-program-and-progression` | Program on recurring + load progression |
| `2026-08-21-polish-mobile-shell-auth` | Shell/auth DS wave B |
| `2026-08-23-polish-student-hub-session-tags-ui` | Student hub / session / tags UI |
| `2026-09-29-polish-trainer-home-bento` | Trainer Home bento variant C |
| `2026-09-29-polish-trainer-home-bento-visual` | Визуальная доводка trainer Home к mock C (date chip, icon stats, timeline, soft-cards) |
| `2026-10-25-add-trainer-gyms` | Залы тренера (название + адрес, база копится из ввода), поиск по залу/району/адресу, валидация телефона и специализаций |
| `2026-10-25-fix-invite-links` | QR/ссылка приглашения на реальный хост (`INVITE_HTTPS_BASE`), `/i/<token>` на вебе, App/Universal Links |
