## 1. Shared calendar book-at-time path

- [x] 1.1 Extend `BookSlotParams` (or add sibling params) with XOR: existing `scheduleSlotId` | `{ startsAt, endsAt, mode }` plus shared student/actor/recurring fields
- [x] 1.2 Implement `CalendarBookingService.bookAtTime` (or unified `book`): coach lock → overlap check against `open`+`booked` → create slot `seriesId=null` → Session+charge → slot `booked` in one transaction (mirror `alternate`)
- [x] 1.3 Keep existing `book(scheduleSlotId)` path unchanged in behavior; refactor only as needed to share charge/session creation helpers
- [x] 1.4 Unit tests: successful book-at-time; overlap with open; overlap with booked; concurrent-style sequential second call conflicts; no orphan open slot on failure

## 2. Sessions API surface

- [x] 2.1 Update `BookSessionDto`: XOR validation for `scheduleSlotId` vs `startsAt`/`endsAt` (+ optional `mode`, default `offline`); require `studentId` for coach book-at-time
- [x] 2.2 Wire `SessionsService.bookForStudent` to choose existing-slot vs book-at-time path
- [x] 2.3 E2E: coach `POST /sessions` with time range books linked student without prior slot; unlinked rejected; both forms of id+range → 400; overlap → 409

## 3. Stricter schedule slot create

- [x] 3.1 Change `SchedulesService.createSlot` overlap query to `status IN ('open', 'booked')` (and `blocked` if following design recommendation)
- [x] 3.2 E2E or unit: creating open slot overlapping a booked slot is rejected; non-overlapping still succeeds

## 4. Recurring sync auto-create

- [x] 4.1 Split `mode_mismatch` from `missing_slot` in `RecurringConflictReason` + `classifyConflict` (exact slot, wrong mode → `mode_mismatch`, no auto-create)
- [x] 4.2 On clean miss (no exact, no open/booked overlap): call book-at-time with occurrence UTC bounds + series mode; increment `slotsCreated`
- [x] 4.3 Extend `RecurringSyncSummary` with `slotsCreated`; keep `booked` / `skippedExisting` / `conflicts`
- [x] 4.4 Ensure auto-created slots use exact `occurrenceToUtcRange` bounds and `seriesId=null`
- [x] 4.5 Keep per-occurrence transactions (do not wrap entire sync loop in one transaction)
- [x] 4.6 Unit tests: auto-create + book; mode_mismatch; held; overlap; idempotent second sync; summary `slotsCreated`
- [x] 4.7 Update recurring e2e that previously expected `missing_slot` for empty calendar → expect booked + `slotsCreated`; add mode_mismatch case

## 5. Delivery verification

- [x] 5.1 Confirm Flutter / orphan screens untouched in this change
- [x] 5.2 Confirm finance path unchanged (per-session charge only)
- [x] 5.3 Run backend unit + affected e2e (`sessions`, `schedules`, `recurring-bookings`)
- [x] 5.4 Optional doc note in `docs/design/availability-recurring-booking.md`: Слой C part 1 API in progress / done
- [x] 5.5 Ready for `/opsx-archive` after apply; follow-up change `add-coach-booking-ux` for Flutter

## Implementation notes

- Overlap statuses: `open` | `booked` | `blocked` (`OCCUPIED_SLOT_STATUSES`).
- `BookAtTimeParams` + `CalendarBookingService.bookAtTime`; existing `book(scheduleSlotId)` preserved.
- Sync summary adds `slotsCreated`; conflict reason `mode_mismatch`.
- Flutter not modified (UX = `add-coach-booking-ux`).
- Unit: calendar-booking + sessions service; e2e: `coach-book-at-time`, `recurring-bookings`.
