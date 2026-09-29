## 1. Backend domain model and migration

- [x] 1.1 Add TypeORM entities: `CoachScheduleSettings`, `ScheduleSeries`, `AvailabilityWindow`, `AvailabilityException` (fields per design.md) under `backend/api/src/database/entity/`
- [x] 1.2 Add repositories for the new entities; register in module/`entities` index
- [x] 1.3 Create migration for tables, FKs, unique coach settings, indexes on `(series_id, day_of_week)` / exception dates
- [x] 1.4 Add domain interfaces (`Params`/`Returns`/types) under schedules (or availability) `interface/` per domain-interfaces skill

## 2. Fixed-grid generator (pure logic)

- [x] 2.1 Implement pure grid helper: windows → candidate intervals given duration, break, timezone (step = duration + break; fit-whole-only)
- [x] 2.2 Apply weekday template + closed/custom exception resolution for each local date in horizon
- [x] 2.3 Unit-test: example 09:00–13:00 / 60 / 15; short window; multi-window day; Monday-first week
- [x] 2.4 Unit-test: DST spring-forward and fall-back for a sample IANA zone (e.g. `Europe/Moscow` or `America/New_York`)

## 3. Schedules API — settings, template, exceptions

- [x] 3.1 DTO + validation for settings upsert (positive duration, break ≥ 0, horizon bounds, IANA timezone, optional per-mode durations)
- [x] 3.2 `GET/PUT /schedule/availability/settings` wired to service with existing `schedules:read_own` / `schedules:create`
- [x] 3.3 `GET/PUT /schedule/availability/template` upsert series + windows; reject overlapping same-day windows
- [x] 3.4 Exceptions list/replace (or CRUD) endpoint(s) for closed / custom_hours
- [x] 3.5 OpenAPI/contract updates for new endpoints; keep `POST/GET/DELETE /schedule/slots` and linked-coach list unchanged
- [x] 3.6 Unit/e2e: settings + template validation and ownership isolation

## 4. Generate operation

- [x] 4.1 `AvailabilityGenerationService` (or schedules method): transaction + coach-row `pessimistic_write`
- [x] 4.2 Insert only non-overlapping candidates with `seriesId`; skip existing identical/overlapping intervals
- [x] 4.3 Preserve booked and held (pending BookingRequest) slots; never delete one-off (`seriesId` null)
- [x] 4.4 Orphan cleanup: remove open unheld series slots absent from desired set
- [x] 4.5 `POST /schedule/availability/generate` returns summary counts; optional `GET .../preview` without persistence
- [x] 4.6 Unit tests: idempotent second generate; booked/held respect; one-off overlap skip
- [x] 4.7 E2E: upsert template → generate → `GET /schedule/slots?from&to` contains series slots; second generate creates 0

## 5. Flutter data layer

- [x] 5.1 Extend `ScheduleRepository` + models for settings, template windows, exceptions, generate summary (and preview if API exists)
- [x] 5.2 Repository tests with mocked Dio for happy-path and mapped API errors
- [x] 5.3 No new state-management packages; keep Bloc/Cubit only

## 6. Flutter availability editor

- [x] 6.1 Add `AvailabilityEditorCubit` + sealed/Equatable states (loading/saving/generating/ready/failure)
- [x] 6.2 Build day-of-week chip picker (Mon-first) as reusable widget
- [x] 6.3 UI sections: «Настройки графика», «Рабочая неделя» (windows, add, delete, «Скопировать на Пн–Пт»), preview, «Исключения»
- [x] 6.4 Use `FyButton` (pill), `FyInputCard`, `FyCard`; reuse `CalendarDateStrip` where date UX fits; Russian copy
- [x] 6.5 Replace `CoachSlotsScreen` on «Доступность» tab in `TrainerCalendarPage` with the new Page/View; keep `FreeTimeSheet` on calendar
- [x] 6.6 Wire save settings/template/exceptions and generate actions; refresh preview/slots after success

## 7. Flutter tests and polish

- [x] 7.1 Cubit unit tests: load, copy Mon–Fri, save, generate success/failure
- [x] 7.2 Widget tests: day chips, add/remove window, exceptions section, generate CTA states, error/retry
- [x] 7.3 Run `dart format`, `flutter analyze`, and schedule/availability test suites
- [x] 7.4 Manual smoke against API on `localhost:3001`: save template → generate → slots appear in «Календарь»; booked/held untouched; FreeTimeSheet still works

## 8. Delivery verification

- [x] 8.1 Compare «Доступность» UI to `docs/assets/fitness-yoda-availability-fixed-grid-v1.png`; note intentional deviations
- [x] 8.2 Confirm finance untouched (`defaultSessionPriceMinor` still quotes student slots)
- [x] 8.3 Confirm non-goals hold: no recurring booking UI, no packages, no gist migration

## Implementation Notes

- OpenAPI YAML отсутствует в `backend/api`; контракт задан Nest DTO + e2e (`test/availability.e2e-spec.ts`).
- Миграция `TrainerAvailability1752850000000` применена; эндпоинты на `:3001` отвечают `401` без JWT (маршрут жив).
- Flutter: вкладка «Доступность» → `AvailabilityEditorPage`; `/schedule/slots` legacy `CoachSlotsScreen` оставлен в router.
- Intentional UI deviations vs concept PNG: нет отдельного визуального «чипа длительности» как hero; exceptions пока только `closed` (custom hours API готов); preview — текстовый список до 12 слотов; `CalendarDateStrip` не вшит (date picker для исключений).
- Finance / packages / gist / recurring booking не трогались.
- Verification: backend unit `fixed-grid` 6/6; e2e availability 3/3; Flutter availability-related 16/16; analyze clean on schedule feature.
