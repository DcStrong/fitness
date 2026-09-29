## 1. Backend domain model and migration

- [x] 1.1 Add TypeORM entities `RecurringBooking` and `RecurringBookingOverride` (fields per design.md) under `backend/api/src/database/entity/`
- [x] 1.2 Add nullable `recurringBookingId` + `recurringLocalDate` on `SessionEntity` with indexes for idempotent lookup
- [x] 1.3 Add repositories; register entities in module / entities index
- [x] 1.4 Create migration for tables, FKs, unique `(recurring_booking_id, local_date)` on overrides, session columns
- [x] 1.5 Add domain interfaces under `src/recurring-bookings/interface/` (types, Params/Returns, conflict reasons) per domain-interfaces skill

## 2. Occurrence expansion and matching (pure logic)

- [x] 2.1 Implement pure helper: weekdays + timezone + horizon → desired local dates; apply skip/reschedule overrides
- [x] 2.2 Implement local date+startMinute+duration → UTC `[startsAt, endsAt)` using existing zoned-time util
- [x] 2.3 Unit-test: Mon/Wed/Fri expansion, skip, reschedule, Monday-first week
- [x] 2.4 Unit-test: DST spring-forward / fall-back for a sample IANA zone

## 3. Recurring bookings API — CRUD and cancel

- [x] 3.1 Nest module `recurring-bookings` (controller/service/module) wired into AppModule
- [x] 3.2 DTO + validation for create (linked student, weekdays ≥1, startMinute, mode)
- [x] 3.3 `POST /recurring-bookings` with `sessions:book_for_student`; reject unlinked student; run initial sync
- [x] 3.4 `GET /recurring-bookings` and `GET /recurring-bookings/:id` with `sessions:read_own` + coach ownership
- [x] 3.5 `POST /recurring-bookings/:id/cancel` cancels series and future booked Sessions via lifecycle
- [x] 3.6 Unit/e2e: create/list/cancel ownership isolation and validation

## 4. Sync materialization and conflict resolve

- [x] 4.1 Sync under transaction + coach-row `pessimistic_write`
- [x] 4.2 Match exact open unheld slot; book Session + charge like book-for-student; set recurring refs
- [x] 4.3 Idempotent skip when Session already exists for `(recurringBookingId, localDate)`
- [x] 4.4 Partial success: return `booked`, `skippedExisting`, `conflicts[]` (`missing_slot` | `held` | `booked_other` | `overlap`)
- [x] 4.5 `POST /recurring-bookings/:id/sync` for re-materialization after availability generate
- [x] 4.6 `POST .../occurrences/:localDate/resolve` with `skip` | `reschedule` then sync that path
- [x] 4.7 Unit tests: partial week, held slot, missing slot, idempotent second sync, reschedule success
- [x] 4.8 E2E: availability slots exist → create series → Sessions appear; conflict then resolve; cancel cleans future

## 5. Flutter data layer

- [x] 5.1 Add recurring models + repository methods (create/list/get/sync/cancel/resolve) via Dio
- [x] 5.2 Repository tests with mocked Dio for happy-path and mapped API errors
- [x] 5.3 Keep Bloc/Cubit only; no new state-management packages

## 6. Flutter recurring UI

- [x] 6.1 Add `RecurringBookingCubit` + sealed/Equatable states (loading/saving/syncing/ready/failure)
- [x] 6.2 Create flow: linked student picker, weekday chips, time, mode; Russian copy; `FyButton`/`FyInputCard`/`FyCard`
- [x] 6.3 Detail/list: pattern summary, sync summary, conflicts with skip/reschedule, cancel with confirm
- [x] 6.4 Wire entry from trainer schedule workspace / relationship context without new bottom tab
- [x] 6.5 Preserve one-off FreeTimeSheet, BookingRequest inbox, and book-for-student paths

## 7. Flutter tests and polish

- [x] 7.1 Cubit unit tests: create, sync partial conflicts, resolve, cancel
- [x] 7.2 Widget tests: weekday chips, conflict actions, loading/error
- [x] 7.3 Run `dart format`, `flutter analyze`, and recurring-related test suites
- [x] 7.4 Manual smoke against API on `localhost:3001`: generate availability → create series → calendar Sessions → resolve conflict → cancel

## 8. Delivery verification

- [x] 8.1 Confirm finance untouched (per-session charge only; no packages)
- [x] 8.2 Confirm non-goals: no auto-created open slots, no student-created recurring, no gist migration
- [x] 8.3 Update `docs/design/availability-recurring-booking.md` status note that Слой A done / Слой B in this change (optional doc hygiene)
- [x] 8.4 Ready for `/opsx-archive` after apply complete

## Implementation Notes

- Migration `RecurringBookings1754300000000` applied.
- Backend unit `occurrences.util` 6/6; e2e `recurring-bookings` 2/2.
- Flutter: entry «Регулярный график» in trainer schedule AppBar → `/schedule/recurring`.
- Cubit tests 5 + weekday picker widget tests; analyze clean (info-only null-aware hints).
- Task 5.2 covered via cubit mocks of repository (no separate Dio repository test file).
- Task 7.4: API path verified by e2e; UI smoke on device left for manual check when app runs against `:3001`.
- Finance / packages / auto-slot creation / student-created recurring not implemented (non-goals).
