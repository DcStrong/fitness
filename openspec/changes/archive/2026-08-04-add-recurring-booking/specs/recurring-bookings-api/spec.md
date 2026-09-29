## ADDED Requirements

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
For each desired occurrence in the horizon, the system SHALL locate an open ScheduleSlot owned by the coach whose absolute start/end matches the occurrence interval and mode, that is not held by a non-expired pending BookingRequest, and SHALL create a `booked` Session with `createdBy=coach` and a Session charge using the same rules as direct book-for-student. The Session MUST reference the RecurringBooking and the occurrence local date. The system MUST NOT invent a new open slot solely to satisfy a recurring occurrence.

#### Scenario: Open slot booked
- **WHEN** sync runs and an open unheld slot exactly matches a desired occurrence
- **THEN** a booked Session and charge are created for that student and linked to the recurring booking

#### Scenario: Missing slot is a conflict
- **WHEN** no matching open slot exists for an occurrence
- **THEN** that occurrence is reported as a conflict with reason `missing_slot` and no Session is created for it

#### Scenario: Held slot is a conflict
- **WHEN** the matching slot has a non-expired pending BookingRequest
- **THEN** that occurrence is reported as a conflict with reason `held`

### Requirement: Sync is idempotent and supports partial success
`POST` sync (including the sync performed on create) MUST be idempotent for already-materialized occurrences, MUST book all currently satisfiable occurrences, and MUST return counts plus the remaining conflict list without failing the whole operation when some dates conflict. Re-running sync after availability generation MAY book previously missing slots.

#### Scenario: Second sync skips existing sessions
- **WHEN** sync has already created a Session for a local date and sync runs again without overrides
- **THEN** that date is counted as skipped/existing and is not double-booked

#### Scenario: Partial conflict success
- **WHEN** Monday’s slot is free but Wednesday’s matching slot is booked by another appointment
- **THEN** Monday is booked, Wednesday appears in conflicts, and the API response is successful with both results

### Requirement: Coach can cancel a recurring booking
The system SHALL allow the owning coach to cancel an active RecurringBooking. Cancellation MUST set status to `cancelled` and MUST cancel future `booked` Sessions belonging to that series through the existing session lifecycle. Completed, cancelled, or no-show Sessions MUST NOT be reversed.

#### Scenario: Cancel stops future materialization
- **WHEN** a coach cancels an active series that has future booked Sessions
- **THEN** the series becomes `cancelled`, future booked Sessions are cancelled via lifecycle, and further sync does not create new Sessions

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
