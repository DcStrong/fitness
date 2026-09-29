## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Auto-created recurring slots use occurrence UTC bounds
Slots created during recurring materialization MUST use the exact `startsAt`/`endsAt` derived by the series timezone conversion for that occurrence and MUST set `seriesId` to null so weekly availability orphan cleanup does not delete them.

#### Scenario: Auto-created slot matches occurrence range
- **WHEN** sync auto-creates a slot for a desired occurrence
- **THEN** the slot’s absolute bounds equal the occurrence UTC range and `seriesId` is null
