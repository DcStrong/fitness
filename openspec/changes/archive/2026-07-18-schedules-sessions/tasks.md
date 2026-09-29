## 1. Architecture & data foundation

- [x] 1.1 Keep `docs/architecture/calendar.md` aligned with implementation decisions during apply
- [x] 1.2 Add TypeORM entities `ScheduleSlot` + `Session` (status enums/CHECK, nullable extension hooks, indexes, unique `schedule_slot_id` on sessions)
- [x] 1.3 Create migration for tables + constraints
- [x] 1.4 Extend permission constants + seed (`schedules:*`, `sessions:*`)
- [x] 1.5 Run migration + seed on local DB

## 2. Backend domain & API

- [x] 2.1 Implement overlap validation for open slots (coach-scoped, half-open intervals)
- [x] 2.2 Nest `schedules` module: create / list own (`from`/`to`) / delete own open slots
- [x] 2.3 List open slots for linked coach (student)
- [x] 2.4 Implement transactional `CalendarBookingService` (lock slot → insert session snapshot → mark slot booked)
- [x] 2.5 Nest `sessions` module: book self / book for linked student; `GET /sessions` with optional range
- [x] 2.6 Enforce coach–student link; reject double-book and overlapping creates
- [x] 2.7 Update Postman collection
- [x] 2.8 API smoke: link → create slots → overlap rejected → book → concurrent-safe second book fails → list

## 3. Mobile schedule & booking UI

- [x] 3.1 Feature folders + repositories/models for schedules and sessions
- [x] 3.2 Trainer: create/list slots screen (RU)
- [x] 3.3 Student: list linked coach open slots + book (RU)
- [x] 3.4 Trainer: book slot for linked student (RU)
- [x] 3.5 Sessions list screen for current user (RU)
- [x] 3.6 Wire go_router routes + home entry points by role

## 4. Verification

- [x] 4.1 Manual smoke mobile against local API (two roles / two clients)
- [x] 4.2 Optional: unit test booking service overlap/double-book or cubit book failure
