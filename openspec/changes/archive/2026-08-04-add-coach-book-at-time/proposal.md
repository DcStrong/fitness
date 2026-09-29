## Why

Тренер может записывать ученика только на уже опубликованный open-слот (`scheduleSlotId`). Если доступность на нужный месяц ещё не сгенерирована, зафиксировать договорённость нельзя: система требует сначала открыть предложение, которое тренер никому публиковать не планировал. То же ограничение блокирует recurring sync — `missing_slot` остаётся конфликтом вместо молчаливого создания факта занятости. Слой C, часть 1 закрывает это на уровне API; Flutter UX — отдельный следующий change.

## What Changes

- Расширить coach book-for-student: принять **либо** существующий `scheduleSlotId`, **либо** raw time range (`startsAt`/`endsAt`/`mode`) — во втором случае атомарно создать `ScheduleSlot` и сразу перевести его в `booked` вместе с Session + charge (open-слот не публикуется).
- В recurring sync при `missing_slot` и отсутствии пересечений — **молча создавать** слот с теми же UTC-границами, что даёт `occurrenceToUtcRange`, и бронировать; в sync summary добавить счётчик созданных слотов.
- Выделить конфликт режима (`mode_mismatch`) отдельно от `missing_slot`: exact-слот с другим mode не решается автосозданием.
- Ужесточить overlap-проверку при создании слота: учитывать `open` **и** `booked` (как в `BookingRequestsService.alternate`), а не только `open`.
- При пересечении с существующей тренировкой/слотом — **блокировать** и возвращать понятный conflict (не silent overwrite).

## Non-goals

- Flutter UX (FAB «+», tap по слоту/пустому времени, переименование входов, поле горизонта в форме) — следующий change `add-coach-booking-ux`.
- Удаление orphan-экранов `CoachBookForStudentScreen` / `CoachSlotsScreen` — вместе с UX-change.
- Изменение student BookingRequest flow, finance-модели, абонементов.
- PostgreSQL gist EXCLUDE, group capacity, gym, waitlist, web.
- Оборачивание всего recurring sync loop в одну транзакцию (сломает partial success); атомарность — на occurrence.

## Capabilities

### New Capabilities

<!-- Нет новых capability: поведение расширяет существующие sessions/calendar/recurring/schedules. -->

### Modified Capabilities

- `sessions-api`: `POST /sessions` для coach принимает XOR `scheduleSlotId` | `{startsAt, endsAt, mode}` + `studentId`; book-at-time атомарно создаёт booked slot + Session + charge.
- `calendar-domain`: прямая запись тренера может материализовать appointment без предварительного open-слота; create-on-demand slot получает `seriesId=null` и сразу `booked`; overlap с booked/open блокирует.
- `recurring-bookings-api`: sync автосоздаёт слот при чистом `missing_slot`; новый reason `mode_mismatch`; sync summary включает `slotsCreated`.
- `schedules-api`: `POST /schedule/slots` отклоняет overlap с `open` **и** `booked` (строже текущего «только open»).

## Impact

- Backend `backend/api/src`: `CalendarBookingService` (общий create+book), `BookSlotParams` union, `BookSessionDto` XOR, `RecurringBookingsService.runSync` / `classifyConflict`, `SchedulesService.createSlot` overlap, e2e.
- API `localhost:3001`: расширенный `POST /sessions` (обратно совместим при передаче `scheduleSlotId`); recurring sync response + conflict enum; более строгий `POST /schedule/slots` (**поведенческое ужесточение** для overlapping booked).
- Flutter: **не трогаем** в этом change (клиент сможет вызывать новый API позже).
- Зависит от archived `add-recurring-booking` и `add-trainer-availability`.
- Референс: `docs/design/availability-recurring-booking.md` (Слой C).
