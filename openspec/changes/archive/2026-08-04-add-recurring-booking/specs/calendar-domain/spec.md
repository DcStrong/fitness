## ADDED Requirements

### Requirement: Recurring booking is a durable coach–student pattern
The calendar domain SHALL support a RecurringBooking as a durable pattern owned by a coach for one linked student, defined by weekdays, local start time-of-day, mode, and timezone. An active series remains in force until cancelled. Package/session-count limits are out of scope for this capability.

#### Scenario: Active until cancel
- **WHEN** a coach creates a recurring booking without an end date
- **THEN** the series stays `active` until an explicit cancel

### Requirement: Desired occurrences are derived then optionally overridden
Desired occurrences MUST be computed by expanding the weekday pattern across the coach generation horizon in the series timezone. A per-source-date override of type `skip` MUST remove that occurrence; type `reschedule` MUST replace its local date and/or start time for materialization only without changing the base pattern.

#### Scenario: Skip removes one date
- **WHEN** an active series includes Wednesday and a skip override exists for a specific Wednesday
- **THEN** that Wednesday is not a desired occurrence for sync

#### Scenario: Reschedule moves one date
- **WHEN** a reschedule override moves one Monday 18:00 occurrence to 19:00 the same local date
- **THEN** sync targets 19:00 for that date and leaves other Mondays at 18:00

### Requirement: Materialization reuses open availability slots
Materializing an occurrence MUST book an existing matching open ScheduleSlot and create a Session; it MUST NOT create availability slots. Matching MUST use absolute UTC bounds derived from local wall time via the series timezone. Pending holds and non-open slots MUST block materialization and surface as conflicts.

#### Scenario: Exact open slot required
- **WHEN** an occurrence needs 18:00–19:00 local and only a 17:30–18:30 open slot exists
- **THEN** the occurrence is a conflict rather than a partial or shifted automatic book

### Requirement: Partial conflicts do not roll back successful books
When some occurrences can be booked and others cannot, the domain MUST keep successful Sessions and expose unresolved conflicts for coach resolution. Conflict reasons MUST distinguish at least missing open slot, held slot, and unavailable/booked slot.

#### Scenario: Mixed week result
- **WHEN** two of three weekly occurrences have free slots and one does not
- **THEN** two Sessions exist and one conflict remains for coach action

### Requirement: Cancelling a series stops future appointments
Cancelling a RecurringBooking MUST prevent further materialization and MUST terminate future `booked` Sessions of that series through the normal session lifecycle. Historical terminal Sessions remain unchanged.

#### Scenario: Future booked cancelled with series
- **WHEN** an active series with a future booked Session is cancelled
- **THEN** that future Session transitions to cancelled and no new Sessions are created for the series
