# recurring-bookings-api Specification

## Purpose
HTTP API for coach-owned recurring bookings: create a weekday pattern for a linked student, materialize occurrences into existing open slots, sync idempotently with partial success, resolve per-occurrence conflicts, cancel or restore a series, and enrich list/get with student identity and next occurrence.

## Requirements

### Requirement: Coach can create an active recurring booking
The system SHALL allow a user with `sessions:book_for_student` to create an active RecurringBooking for a linked student. The booking MUST include one or more weekdays (Monday=1 … Sunday=7), a local start time-of-day, and mode `online` or `offline`. The student MUST have an active coach–student relationship with the authenticated coach. On create the system MUST snapshot an IANA timezone (from coach schedule settings unless overridden) and MUST run an initial materialization sync for the generation horizon.

#### Scenario: Coach creates Mon/Wed/Fri series
- **WHEN** a coach submits weekdays `{1,3,5}`, local start 18:00, mode `offline`, and a linked student id
- **THEN** the system stores an active RecurringBooking and returns it with an initial sync summary

#### Scenario: Unlinked student rejected
- **WHEN** a coach attempts to create a recurring booking for a student without an active relationship
- **THEN** the system rejects the request

#### Scenario: Empty weekdays rejected
- **WHEN** a coach submits an empty weekday set
- **THEN** the system rejects the request

### Requirement: Materialization books matching open slots
For each desired occurrence in the horizon, the system SHALL first locate an open ScheduleSlot owned by the coach whose absolute start/end matches the occurrence interval and mode, that is not held by a non-expired pending BookingRequest, and SHALL create a `booked` Session with `createdBy=coach` and a Session charge using the same rules as direct book-for-student. The Session MUST reference the RecurringBooking and the occurrence local date.

When no matching slot exists and no open or booked slot of the coach overlaps the occurrence interval, the system SHALL silently create a ScheduleSlot (`seriesId` null) with those exact UTC bounds and mode, then book it in the same atomic path as coach book-at-time. When an exact slot exists with a different mode, the occurrence MUST be reported as conflict reason `mode_mismatch` and MUST NOT auto-create a second slot. Held, booked-other, and non-exact overlap cases MUST remain conflicts without auto-create.

#### Scenario: Open slot booked
- **WHEN** sync runs and an open unheld slot exactly matches a desired occurrence
- **THEN** a booked Session and charge are created for that student and linked to the recurring booking

#### Scenario: Missing slot is auto-created and booked
- **WHEN** no matching open slot exists for an occurrence and no open or booked slot overlaps the interval
- **THEN** the system creates a ScheduleSlot and a booked Session for that occurrence and does not report a conflict

#### Scenario: Held slot is a conflict
- **WHEN** the matching slot has a non-expired pending BookingRequest
- **THEN** that occurrence is reported as a conflict with reason `held`

#### Scenario: Mode mismatch is a conflict
- **WHEN** an exact slot exists for the occurrence interval but its mode differs from the series mode
- **THEN** that occurrence is reported as a conflict with reason `mode_mismatch` and no second slot is created

### Requirement: Sync is idempotent and supports partial success
`POST` sync (including the sync performed on create) MUST be idempotent for already-materialized occurrences, MUST book all currently satisfiable occurrences (including via silent slot creation when allowed), and MUST return counts plus the remaining conflict list without failing the whole operation when some dates conflict. The sync summary MUST include `booked`, `skippedExisting`, `slotsCreated`, and `conflicts`. Re-running sync after availability generation or after prior auto-creates MUST NOT double-book.

#### Scenario: Second sync skips existing sessions
- **WHEN** sync has already created a Session for a local date and sync runs again without overrides
- **THEN** that date is counted as skipped/existing and is not double-booked

#### Scenario: Partial conflict success
- **WHEN** Monday’s slot is free but Wednesday’s matching slot is booked by another appointment
- **THEN** Monday is booked, Wednesday appears in conflicts, and the API response is successful with both results

#### Scenario: Sync reports slots created
- **WHEN** sync auto-creates slots for two occurrences with no prior availability
- **THEN** the response `slotsCreated` is at least 2 and those dates are counted in `booked`

### Requirement: Coach can cancel a recurring booking
The system SHALL allow the owning coach to cancel an active RecurringBooking. Cancellation MUST set status to `cancelled` and MUST cancel future `booked` Sessions belonging to that series through the existing session lifecycle with slot release (`releaseSlot`) so linked ScheduleSlots become `open`. Completed, cancelled, or no-show Sessions MUST NOT be reversed.

#### Scenario: Cancel stops future materialization
- **WHEN** a coach cancels an active series that has future booked Sessions
- **THEN** the series becomes `cancelled`, future booked Sessions are cancelled via lifecycle, linked slots become `open`, and further sync does not create new Sessions

### Requirement: Per-occurrence skip and reschedule
The system SHALL allow the owning coach to resolve a specific local date with `skip` or `reschedule`. Skip MUST prevent materialization for that source date. Reschedule MUST store a new local date and/or start time for that occurrence and MUST attempt to book the new interval on resolve/sync. Overrides MUST be unique per `(recurringBookingId, sourceLocalDate)`.

#### Scenario: Skip occurrence
- **WHEN** a coach marks a conflicting local date as skip
- **THEN** sync does not book that date and the conflict is cleared or marked resolved as skipped

#### Scenario: Reschedule occurrence
- **WHEN** a coach reschedules a date to another local start that has a matching open slot
- **THEN** the system books a Session at the new interval and links it to the recurring booking

### Requirement: Coach can list and read own recurring bookings
The system SHALL allow a coach with `sessions:read_own` to list and read RecurringBookings they own, including status, pattern fields, and the latest known conflict summary when available from sync state or an explicit sync response retained for the client.

#### Scenario: List active series
- **WHEN** a coach requests their recurring bookings
- **THEN** the response includes their series with student id, weekdays, start time, mode, and status

### Requirement: Auto-created recurring slots use occurrence UTC bounds
Slots created during recurring materialization MUST use the exact `startsAt`/`endsAt` derived by the series timezone conversion for that occurrence and MUST set `seriesId` to null so weekly availability orphan cleanup does not delete them.

#### Scenario: Auto-created slot matches occurrence range
- **WHEN** sync auto-creates a slot for a desired occurrence
- **THEN** the slot’s absolute bounds equal the occurrence UTC range and `seriesId` is null

### Requirement: Recurring booking list includes student identity
`GET /recurring-bookings` and `GET /recurring-bookings/:id` responses SHALL include `studentDisplayName` (nullable) and `studentEmail` (nullable) for the linked student, resolved from profile display name and user email.

#### Scenario: List returns student fields
- **WHEN** a coach lists recurring bookings
- **THEN** each item includes `studentDisplayName` and `studentEmail`

### Requirement: Recurring booking exposes next occurrence date
For an **active** RecurringBooking, list and get responses SHALL include `nextOccurrenceLocalDate` (nullable ISO local date `YYYY-MM-DD`) for the nearest future occurrence in the booking timezone according to weekdays, startMinute, and overrides. For **cancelled** bookings the field SHALL be `null`.

#### Scenario: Active list includes next occurrence
- **WHEN** a coach lists active recurring bookings
- **THEN** each active item includes `nextOccurrenceLocalDate` when a future occurrence exists within the computable horizon, otherwise `null`

#### Scenario: Cancelled has no next occurrence
- **WHEN** a coach lists cancelled recurring bookings
- **THEN** each item has `nextOccurrenceLocalDate` equal to `null`

### Requirement: Create rejects active pattern duplicate
The pattern key is `(coachId, studentId, sorted weekdays, startMinute, mode)`. When creating a RecurringBooking, if an **active** series with the same key already exists for the coach, the system SHALL respond with `409 Conflict`, include `existingId` of that series, and MUST NOT create a new row.

#### Scenario: Duplicate active create
- **WHEN** a coach creates a series whose pattern matches an existing active series
- **THEN** the response is 409 with `existingId` and no new booking is created

### Requirement: Create reactivates cancelled pattern twin
When creating a RecurringBooking, if no active series matches the pattern but one or more **cancelled** series match, the system SHALL reactivate the newest cancelled twin (`status=active`, `cancelledAt=null`), apply optional horizon override from the request, run sync, and return `{ booking, sync }` with the **same id**. A new row MUST NOT be inserted.

#### Scenario: Create after cancel reuses id
- **WHEN** a coach cancels a series and then creates again with the same student, weekdays, startMinute, and mode
- **THEN** the response is success with the cancelled series id reactivated and status `active`

### Requirement: Restore cancelled recurring series
The system SHALL allow the owning coach to restore a **cancelled** RecurringBooking via an explicit restore endpoint (e.g. `POST /recurring-bookings/:id/restore`). Restore SHALL set `status=active`, clear `cancelledAt`, run sync, and return `{ booking, sync }` with the same id. Restoring an already **active** series MUST be rejected. If another **active** series already matches the same pattern key, restore MUST be rejected with `409` and `existingId`.

#### Scenario: Restore cancelled series
- **WHEN** a coach restores a cancelled series
- **THEN** the series becomes `active`, `cancelledAt` is null, sync runs, and the response uses the same booking id

#### Scenario: Restore active rejected
- **WHEN** a coach attempts to restore an active series
- **THEN** the system rejects the request

#### Scenario: Restore conflicts with other active pattern
- **WHEN** a coach restores a cancelled series whose pattern matches a different active series
- **THEN** the response is 409 with `existingId` of the conflicting active series

### Requirement: Cancel series releases future slots
When a coach cancels an active RecurringBooking, the system SHALL cancel future `booked` Sessions of that series AND set each linked ScheduleSlot status to `open` so the time becomes bookable again. Completed, cancelled, and no-show Sessions MUST NOT be reversed. A normal one-off session cancel without `releaseSlot` MAY leave the slot booked.

#### Scenario: Cancel frees matching slots
- **WHEN** a coach cancels an active series that has future booked Sessions on slots
- **THEN** those Sessions become `cancelled` and their ScheduleSlots become `open`

### Requirement: List recurring bookings by status
`GET /recurring-bookings` SHALL accept optional `status=active|cancelled|all` and MUST default to `active` when omitted.

#### Scenario: Default list is active only
- **WHEN** a coach lists recurring bookings without a status query
- **THEN** only `active` series are returned

#### Scenario: Archive list
- **WHEN** a coach lists with `status=cancelled`
- **THEN** only cancelled series are returned

### Requirement: Hard delete cancelled series
The system SHALL allow the owning coach to `DELETE` a RecurringBooking only when its status is `cancelled`. Active series MUST be rejected. Delete MUST remove the series and its occurrence overrides.

#### Scenario: Delete cancelled series
- **WHEN** a coach deletes a cancelled series
- **THEN** the series is removed and subsequent GET returns not found

#### Scenario: Delete active rejected
- **WHEN** a coach attempts to delete an active series
- **THEN** the system rejects the request

### Requirement: Recurring booking exposes and persists its workout program
The system SHALL allow the owning coach to GET and PUT the workout program as a subresource of the RecurringBooking. GET of the series MAY include a summary that a program exists and the count of day items. Cancelled series MUST reject program upsert. Recurring sync MUST apply an existing program to newly booked occurrences in the current horizon.

#### Scenario: Get program after upsert
- **WHEN** the coach PUTs a valid program and then GETs it
- **THEN** weekdays, template ids, student copy ids, horizon, and progression rules are returned

#### Scenario: Sync applies program
- **WHEN** sync creates a new booked occurrence for a weekday that has program items
- **THEN** that session receives those workout items and snapshots

#### Scenario: Cancelled series cannot upsert program
- **WHEN** the coach PUTs a program on a cancelled series
- **THEN** the system rejects the request
