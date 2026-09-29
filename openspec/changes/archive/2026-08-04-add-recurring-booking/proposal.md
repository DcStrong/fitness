## Why

Слой A уже даёт тренеру недельный шаблон и генерацию open-слотов, но закрепить ученика за постоянным графиком (Пн/Ср/Пт 18:00) по-прежнему нельзя: каждая тренировка — ручная разовая запись. Без Слоя B тренер вынужден повторять book-for-student каждую неделю, а конфликты «это время уже занято» не собираются в один workflow согласования.

## What Changes

- Добавить сущность **RecurringBooking**: тренер закрепляет связанного ученика за набором дней недели + локальным временем старта + режимом (`online`/`offline`); серия активна до отмены (абонемент/лимит — вне scope).
- Добавить **материализацию** на горизонт coach schedule settings: для каждой occurrence найти подходящий open-слот и создать `booked` Session (coach-driven, как book-for-student) атомарно с charge; идемпотентно при повторном sync.
- При частичных конфликтах (слот занят/held/отсутствует) — создать то, что возможно, и вернуть список конфликтов для ручного сдвига (alternate time на конкретную дату).
- Добавить **per-occurrence override**: разово пропустить дату или сдвинуть время одной occurrence без изменения серии.
- Расширить API (sessions/schedules или отдельный recurring module) CRUD серии + sync/materialize + resolve conflict / override.
- Flutter: UI тренера для создания/просмотра/отмены регулярного графика ученика и разбора конфликтов; календарь показывает серии как обычные Sessions без отдельного «recurrence engine» в UI.
- Сохранить существующие разовые пути: BookingRequest, book-for-student, FreeTimeSheet.

## Non-goals

- Абонемент / счётчик «осталось N» — отдельный change `add-session-packages`.
- Изменение finance-модели, предоплата, эквайринг; charge по-прежнему на каждую фактическую Session.
- Student-driven создание recurring (только coach-driven на MVP).
- Автосоздание missing open-слотов вне шаблона доступности (слот должен уже существовать из Слоя A / FreeTimeSheet; иначе — конфликт).
- PostgreSQL gist overlap, group capacity, gym, waitlist, web console, push/realtime.
- Полный RRULE/iCal; модель — явные weekdays + local time + horizon sync.

## Capabilities

### New Capabilities

- `recurring-bookings-api`: HTTP API создания/чтения/отмены регулярного графика, sync материализации, per-occurrence override и разрешения конфликтов.
- `mobile-recurring-booking`: Flutter UI тренера для закрепления ученика за графиком, списка серий, конфликтов и разовых сдвигов (Russian copy).

### Modified Capabilities

- `calendar-domain`: доменные инварианты RecurringBooking, материализации Session из open-слота, частичных конфликтов и occurrence overrides.
- `sessions-api`: материализация recurring создаёт Session с `createdBy=coach` и charge как book-for-student; list/read без breaking changes.
- `mobile-schedule-booking`: из workspace расписания тренер может открыть поток «регулярный график» для связанного ученика; разовые записи и заявки сохраняются.

## Impact

- Backend `backend/api/src`: новые TypeORM entities + migration (`recurring_bookings`, occurrence overrides), service с coach-row lock, endpoints, unit + e2e (частичный конфликт, idempotent sync, override).
- PostgreSQL: таблицы серии и overrides; Sessions/Slots без breaking schema для существующих полей (возможны nullable FK на recurring booking / occurrence).
- API `localhost:3001`: новые authenticated coach endpoints; существующие booking/session flows без breaking changes.
- Flutter `app/fitness_app`: repository + Cubit/экраны recurring; интеграция в schedule workspace; `FyCard`/`FyButton`/`FyInputCard`/day-of-week chips; Bloc only.
- Зависит от уже archived `add-trainer-availability` (settings horizon, open slots, timezone).
- Референс: `docs/design/availability-recurring-booking.md` (Слой B).
