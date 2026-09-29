## Why

На экране ученика «Запись к тренеру» список показывает `open` слоты, на которые `POST /booking-requests` сразу отвечает конфликтом «decision window has already closed». Клиент мапит это в «время истекло», хотя слот визуально свободен. Причина: заявка должна быть создана не позже чем за 2 часа до `startsAt`, а список requestable слотов фильтрует по `now` и по `ends_at`, поэтому уже начавшиеся и «слишком близкие» слоты остаются в UI.

## What Changes

- Список requestable слотов связанного тренера возвращает только те `open` слоты, на которые ещё можно подать заявку: `startsAt` строго позже `now + 2 часа` (тот же cutoff, что `calculateBookingRequestExpiry`).
- Фильтр по нижней границе для этого списка — по `starts_at`, не по `ends_at` (идущий сейчас слот не requestable).
- Мобильный экран «Запись к тренеру»: пустое состояние и конфликт при закрытом окне объясняют правило «за 2 часа до начала», а не общее «время истекло».
- Если создание всё же получило closed-window conflict — обновить список слотов (уже есть refresh на conflict).

## Capabilities

### New Capabilities

_(нет)_

### Modified Capabilities

- `schedules-api`: linked-student requestable list MUST omit slots whose booking-request decision window is already closed (including in-progress slots).
- `mobile-schedule-booking`: student booking UI MUST not present unrequestable slots as sendable; Russian copy MUST explain the 2-hour cutoff.

## Impact

- NestJS: `listOpenForLinkedCoach` / `findRequestableForCoach`; reuse `BOOKING_REQUEST_SLOT_CUTOFF_HOURS` from booking-request rules. No schema/migration.
- Flutter: `student_book_screen.dart`, `booking_requests_repository.dart` error mapping + tests.
- Specs: `schedules-api`, `mobile-schedule-booking`.

## Non-goals

- Changing the 12h / 2h expiry policy itself.
- Trainer calendar listing of own open slots (trainers still see in-progress/open slots they own).
- Timezone conversion of slot instants (API already stores UTC instants).
- Recurring bookings or coach book-at-time flow.
