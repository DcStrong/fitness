## Context

Слой A (`add-trainer-availability`, archived) уже даёт тренеру:

- `CoachScheduleSettings` (timezone, duration, break, `horizonWeeks`);
- недельный шаблон + exceptions + fixed-grid генерацию open `ScheduleSlot` с `seriesId`;
- Flutter-редактор «Доступность».

Запись ученика сегодня разовая: BookingRequest (студент → тренер) или book-for-student (тренер сразу создаёт Session + charge). Постоянный график «Пн/Ср/Пт 18:00 для Ивана» отсутствует: тренер вручную бронирует каждую неделю.

Этот change реализует **Слой B** из `docs/design/availability-recurring-booking.md`: coach-driven RecurringBooking, материализация Sessions на горизонт, частичные конфликты, per-occurrence override. Абонементы и finance-модель не входят.

Constraints: NestJS + TypeORM, Flutter Bloc/Cubit only, API `localhost:3001`, Russian UI, permissions уже есть (`sessions:book_for_student`, `sessions:read_own`, relationship link). Overlap — app-level half-open + coach-row `pessimistic_write`.

## Goals / Non-Goals

**Goals:**

- Тренер закрепляет связанного ученика за weekdays + local start time + mode.
- Sync материализует `booked` Sessions на горизонт settings, переиспользуя существующие open-слоты.
- Частичный успех + явный список конфликтов для ручного сдвига.
- Разовый skip/reschedule одной даты без ломки серии.
- Flutter UI в trainer schedule workspace.

**Non-Goals:**

- `add-session-packages`, предоплата, эквайринг.
- Student-created recurring.
- Автогенерация missing open-слотов (это Слой A / FreeTimeSheet).
- RRULE/iCal, gist EXCLUDE, groups, gym, web, push.

## Decisions

### 1. Отдельная сущность `RecurringBooking`, не `ScheduleSeries.kind`

`schedule_series` сейчас 1:1 coach ↔ `weekly_availability` (unique `(coachId, kind)`). Recurring — много серий на тренера (по ученикам/графикам).

Таблица `recurring_bookings`:

| Поле | Смысл |
|---|---|
| `id` | UUID |
| `coachId` / `studentId` | FK users; student MUST быть linked |
| `weekdays` | set `1..7` (Mon-first), ≥1 день |
| `startMinute` | локальные минуты от полуночи (старт) |
| `mode` | `online` \| `offline` |
| `timezone` | snapshot IANA на create (обычно из coach settings) |
| `status` | `active` \| `cancelled` |
| `horizonWeeksOverride` | nullable; иначе settings.horizonWeeks |
| timestamps / `cancelledAt` |

Длительность occurrence = coach settings duration для mode (per-mode override → default).

Альтернатива — строки в `schedule_series` с `kind=recurring_student`. Отклонена: ломает unique weekly template и смешивает availability vs appointment.

### 2. Occurrence = виртуальная дата + optional override row

Не материализуем все даты заранее как rows. Desired occurrences = разворот weekdays на `[today .. horizonEnd]` в timezone серии, минус overrides `skip`, с учётом `reschedule` (другой local start / дата).

Таблица `recurring_booking_overrides`:

| Поле | Смысл |
|---|---|
| `recurringBookingId` | FK |
| `localDate` | YYYY-MM-DD в timezone серии |
| `type` | `skip` \| `reschedule` |
| `newStartMinute` / `newLocalDate` | для reschedule (nullable) |
| unique `(recurringBookingId, localDate)` | одна override на исходную дату |

Session после успешной материализации хранит nullable `recurringBookingId` (+ optional `recurringLocalDate`) для идемпотентности и отмены хвоста.

### 3. Материализация = book existing open slot (не invent time)

Для каждой desired occurrence:

1. Вычислить UTC `[startsAt, endsAt)` из local date + startMinute + duration.
2. Найти **точный** open `ScheduleSlot` coach с тем же `startsAt`/`endsAt` (или documented equality on startsAt + matching duration) и совместимым mode; слот не held pending BookingRequest.
3. Если найден — атомарно book-for-student (Session `booked`, `createdBy=coach`, charge как сейчас), привязать Session → recurring ids.
4. Если Session на эту `(recurringBookingId, localDate)` уже есть — skip (идемпотентность).
5. Иначе конфликт: `missing_slot` | `held` | `booked_other` | `overlap` (+ optional suggested neighbor open slots later).

**Не** создавать open-слот «ради серии». Нет слота → конфликт (тренер правит доступность или сдвигает occurrence).

Альтернатива — создавать one-off slot + book. Отклонена: обходит Слой A и ломает фикс-сетку/перерывы.

### 4. Partial success + sync API

`POST /recurring-bookings` создаёт active серию и сразу запускает sync.
`POST /recurring-bookings/:id/sync` повторяет материализацию (после generate availability / сдвига горизонта).

Ответ sync:

```text
{ booked: number, skippedExisting: number, conflicts: Conflict[] }
```

Конфликтные даты **не** блокируют успешные. UI показывает conflicts для resolve.

Cancel серии (`POST .../cancel` или `DELETE`): status=cancelled; **будущие** `booked` Sessions этой серии → cancel lifecycle (существующий session cancel), past/completed не трогать. Точная семантика cancel будущих — через существующий sessions lifecycle API внутри транзакции.

### 5. Resolve conflict = override + sync одной даты

`POST /recurring-bookings/:id/occurrences/:localDate/resolve`:

- `skip` — override skip (не бронировать);
- `reschedule` — override на новый local time/date + сразу попытка book на новый интервал.

Не делаем counter-offer студенту: coach-driven.

### 6. API surface и permissions

Новый Nest module `recurring-bookings` (или под `sessions`), endpoints:

| Method | Path | Permission |
|---|---|---|
| `POST` | `/recurring-bookings` | `sessions:book_for_student` |
| `GET` | `/recurring-bookings` | `sessions:read_own` (coach list own; student may list own later — MVP coach-first) |
| `GET` | `/recurring-bookings/:id` | `sessions:read_own` + ownership |
| `POST` | `/recurring-bookings/:id/sync` | `sessions:book_for_student` |
| `POST` | `/recurring-bookings/:id/cancel` | `sessions:book_for_student` |
| `POST` | `/recurring-bookings/:id/occurrences/:localDate/resolve` | `sessions:book_for_student` |

Все операции под coach-row lock. Student read optional MVP+.

### 7. Flutter

- Models + repository methods.
- `RecurringBookingCubit` (list/create/sync/cancel/resolve).
- Entry: из schedule workspace / student relationship («Регулярный график»).
- Create form: student picker (linked), day chips, time, mode; reuse availability day-of-week chips / `FyInputCard` / `FyButton`.
- Detail: upcoming materialized sessions + conflicts list + skip/reschedule actions.
- Calendar продолжает показывать Sessions; отдельный recurrence renderer не нужен.

### 8. Types в `interface/`

Все Params/Returns/Conflict unions в `src/recurring-bookings/interface/` (domain-interfaces skill). Entity только `import type`.

## Risks / Trade-offs

- [Нет open-слота на нужное время] → Конфликт `missing_slot`; UX направляет в «Доступность»/FreeTimeSheet; не автосоздаём слот.
- [После generate availability горизонт уехал вперёд] → Coach/UI вызывает sync; опционально later job — вне MVP.
- [Cancel серии массово трогает Sessions] → Только future `booked`; completed/history нетронуты; audit через session lifecycle.
- [Точное совпадение startsAt хрупко при DST] → Считать UTC через ту же zoned-time util, что availability; unit-тесты DST.
- [Два recurring на одно время одному coach] → Overlap: вторая материализация получит conflict; validation MAY warn on create if pattern overlaps existing active series for same coach (soft check).
- [Student UX] → MVP coach-first; student видит обычные Sessions в календаре/списке.

## Migration Plan

1. Migration: `recurring_bookings`, `recurring_booking_overrides`, nullable columns на `sessions` (`recurring_booking_id`, `recurring_local_date`).
2. Backend module + e2e.
3. Flutter data + UI.
4. Rollback: feature-flag не обязателен; drop tables + null columns; existing non-recurring Sessions unaffected.

## Open Questions

- Нужен ли student `GET` своих recurring на MVP, или достаточно списка Sessions? (Рекомендация: coach-only list в v1.)
- При cancel серии: soft-cancel Sessions сразу или оставить booked до ручного cancel? (Рекомендация: auto-cancel future booked с standard lifecycle reason `recurring_cancelled`.)
- Equality слота: только exact `startsAt`, или допуск ±N минут? (Рекомендация: exact `startsAt` + `endsAt` match duration.)
