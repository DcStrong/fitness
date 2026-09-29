## Why

Связь тренер↔ученик уже есть (QR). Следующий шаг — **календарь и запись**: это ядро продукта (занятия, потом подтверждение, история, фактуры, планы). Нужна аккуратная backend-архитектура «на вырост», при этом MVP-реализация остаётся простой.

## What Changes

- **Architecture-first backend calendar**: разделение availability (слоты) vs appointments (sessions), инварианты времени/конфликтов, точки расширения (recurrence, gym, groups, lifecycle).
- Документ `docs/architecture/calendar.md` + детальный `design.md` change.
- TypeORM-модель и Nest-модули под эту модель (MVP-срез без лишних фич).
- API: слоты тренера; booking студентом / тренером за linked student; list sessions.
- Permissions + seed.
- Flutter: минимальный UI графика и записи (RU), после backend.

## Non-goals (MVP slice)

- Complete / cancel / no_show + history events (фаза `session-lifecycle-history`).
- Push / email, invoices, training plans/tags.
- Группы (N студентов), обязательный Gym, Universal calendar sync (Google/Apple).
- Полноценный recurring engine в UI (правила recurrence — только задел в модели/доке).
- Web / Next.js.

## Capabilities

### New Capabilities

- `schedules-api`: availability slots тренера + правила свободности.
- `sessions-api`: booked appointments 1:1 + list.
- `mobile-schedule-booking`: Flutter UI графика/записи.
- `calendar-domain` (spec): backend-инварианты календаря (время, конфликты, разделение slot/session) как основа продукта.

### Modified Capabilities

- `access-control`: permissions `schedules:*`, `sessions:*`.
- `mobile-app-shell`: маршруты графика / занятий.
- `coach-student-link`: booking только при активной связи.

## Impact

- Backend: главный фокус — `backend/api` modules + migrations + domain services.
- Docs: `docs/architecture/calendar.md`, domain processes/entities alignment.
- Mobile: тонкий клиент поверх API.
- Порядок: **документированная модель → backend → Flutter**.
