# calendar-domain Specification

## Purpose
Canonical calendar model: bookable availability (`ScheduleSlot`) is separate from appointments (`Session`). Booking creates a Session and closes the slot atomically.
## Requirements
### Requirement: Calendar separates availability from appointments
The backend calendar SHALL model bookable availability (`ScheduleSlot`), pre-appointment intent (`BookingRequest`), and confirmed appointments (`Session`) separately. A student request MUST NOT create a Session. Accepting a valid request or direct coach booking SHALL create a Session and mark its resolved availability slot as no longer open. Session times MUST be snapshotted from the resolved slot at booking time.

#### Scenario: Student request precedes appointment
- **WHEN** a valid student request is created against an open slot
- **THEN** a pending BookingRequest exists while no Session or charge exists

#### Scenario: Accepted request converts slot into booked session
- **WHEN** the coach accepts a valid pending request at its requested slot
- **THEN** a Session exists with status `booked` and the slot is no longer open for another booking

#### Scenario: Coach direct booking remains immediate
- **WHEN** a coach directly books a linked student into an own open slot
- **THEN** a Session is created without requiring a BookingRequest

### Requirement: Time ranges are absolute and valid
Schedule slots and sessions SHALL store `startsAt`/`endsAt` as absolute timestamps (`timestamptz` / ISO-8601). The system MUST reject ranges where `endsAt` is not after `startsAt`.

#### Scenario: Invalid range rejected
- **WHEN** a client submits `endsAt` ≤ `startsAt`
- **THEN** the system rejects the request

### Requirement: Open availability slots for a coach must not overlap
The system SHALL prevent a coach from having two open availability slots with overlapping time ranges (half-open `[startsAt, endsAt)`).

#### Scenario: Overlapping open slot rejected
- **WHEN** a trainer creates an open slot that overlaps an existing open slot of the same coach
- **THEN** the system rejects the request

### Requirement: Booking is atomic against double-book
Direct coach booking and BookingRequest acceptance/alternate resolution SHALL run as server-side atomic operations such that concurrent operations cannot create more than one Session for the same slot or more than one Session/charge for the same request.

#### Scenario: Concurrent accept of same request
- **WHEN** two acceptance operations target the same pending request concurrently
- **THEN** exactly one creates a Session and charge and the other fails with a conflict-style error

#### Scenario: Direct booking races request acceptance
- **WHEN** direct coach booking and request acceptance concurrently target the same open slot
- **THEN** exactly one operation books the slot and the other fails without partial records

### Requirement: Schema reserves extension points without requiring MVP features
The persistence model SHALL allow future recurrence, gym, and capacity/groups without renaming the core Slot/Session concepts (for example nullable `seriesId`/`gymId`, `capacity` defaulting to 1, and session status values that include lifecycle states).

#### Scenario: New sessions still start booked
- **WHEN** a booking succeeds
- **THEN** the created session status is `booked` before any lifecycle transition

### Requirement: Session lifecycle transitions are explicit and terminal
The calendar domain SHALL allow only transitions from `booked` to one of `completed`, `cancelled`, or `no_show`. Terminal statuses MUST NOT transition further in this phase.

#### Scenario: Illegal reverse transition rejected
- **WHEN** a client attempts to move a `completed` session back to `booked`
- **THEN** the system rejects the request

### Requirement: History events are the audit trail for lifecycle
Each successful lifecycle transition SHALL be represented by a durable history event linked to the session (append-only).

#### Scenario: Transition and history are atomic
- **WHEN** a lifecycle transition succeeds
- **THEN** both the new session status and the corresponding history event are persisted together

### Requirement: Pending request holds availability
A non-expired pending BookingRequest SHALL make its requested slot unavailable to other student requests and SHALL prevent deletion of that slot. Rejected, withdrawn, and expired requests SHALL release the logical hold.

#### Scenario: Held slot omitted from student availability
- **WHEN** an open slot has a non-expired pending request
- **THEN** another student does not receive that slot as requestable availability

#### Scenario: Terminal request releases hold
- **WHEN** a pending request becomes rejected, withdrawn, or expired
- **THEN** its still-open requested slot can be listed and requested again

### Requirement: Alternate request resolution preserves canonical slots
Resolving a request at another time SHALL create a one-off ScheduleSlot and then create the Session from that slot. The original requested slot MUST remain open unless separately changed.

#### Scenario: Alternate appointment is materialized
- **WHEN** a coach assigns a conflict-free alternate time
- **THEN** the Session snapshots duration and mode through a new one-off slot and the original slot remains available

### Requirement: Trainer manages schedule settings
The system SHALL persist per-coach schedule settings including IANA timezone, default session duration in minutes, optional break minutes between sessions, generation horizon in weeks, optional per-mode durations for `online` and `offline`, and a default slot mode. Duration values MUST be positive; break minutes and horizon MUST be non-negative within configured bounds. Settings MUST be owned by the authenticated coach and MUST NOT alter finance defaults.

#### Scenario: Coach upserts settings
- **WHEN** a coach saves valid duration, break, horizon, timezone and optional per-mode durations
- **THEN** the system stores those settings for that coach and returns them on subsequent read

#### Scenario: Invalid duration rejected
- **WHEN** a coach submits a non-positive default duration or negative break minutes
- **THEN** the system rejects the request

### Requirement: Weekly availability template defines working windows
The system SHALL allow a coach to define a weekly availability template with zero or more working windows per weekday Monday through Sunday. Each window MUST use local time-of-day bounds in the coach timezone as a half-open range. Multiple windows on the same weekday MUST NOT overlap. The template SHALL be associated with a durable series identity used as `seriesId` on generated slots.

#### Scenario: Coach saves Monday windows
- **WHEN** a coach upserts two non-overlapping Monday windows such as 09:00–13:00 and 14:00–18:00
- **THEN** the template stores both windows for Monday under the coach series

#### Scenario: Overlapping windows rejected
- **WHEN** a coach submits overlapping windows on the same weekday
- **THEN** the system rejects the request

### Requirement: Date exceptions override the weekly template
The system SHALL allow exceptions for specific local calendar dates: a closed day with no windows, or custom hours that replace the weekday template for that date only. Exception dates are interpreted in the coach timezone.

#### Scenario: Closed-day exception
- **WHEN** a coach marks a local date as closed
- **THEN** generation produces no slots from the weekly template on that local date

#### Scenario: Custom-hours exception
- **WHEN** a coach sets custom hours for a local date
- **THEN** generation uses only those custom windows for that date instead of the weekday template

### Requirement: Fixed-grid generation materializes open slots
Given settings and an effective window, the system SHALL generate discrete open `ScheduleSlot` records on a fixed grid where the step equals session duration plus break minutes. A candidate slot MUST be created only when its full `[start, start+duration)` fits inside the window. Generated slots MUST store absolute UTC timestamps, the series id, and the resolved mode. Flexible arbitrary start times inside a window MUST NOT be offered by this generator.

#### Scenario: Grid fits whole slots only
- **WHEN** a local window is 09:00–13:00 with duration 60 and break 15
- **THEN** the generator creates 09:00–10:00, 10:15–11:15 and 11:30–12:30 and does not create 12:45–13:45

#### Scenario: Empty remainder skipped
- **WHEN** a window is shorter than one full duration
- **THEN** no slot is created for that window

### Requirement: Generation is idempotent and preserves booked or held slots
Slot generation SHALL run as an atomic coach-scoped operation. It MUST NOT create a duplicate open slot for an identical interval that already exists. It MUST NOT delete, recreate, or overwrite booked slots or open slots with a non-expired pending BookingRequest. It MUST NOT remove one-off slots (`seriesId` null). Re-running generation without template changes MUST report no new creates for already materialized intervals. Open unheld series slots that are no longer produced by the current template MAY be removed as orphan cleanup.

#### Scenario: Second generate is idempotent
- **WHEN** a coach runs generate twice with an unchanged template and settings
- **THEN** the second run creates zero additional slots for the same intervals

#### Scenario: Booked slot preserved
- **WHEN** a previously generated interval is already booked
- **THEN** generation leaves that slot unchanged and does not create a conflicting open duplicate

#### Scenario: Held slot preserved
- **WHEN** an open series slot has a non-expired pending BookingRequest
- **THEN** generation does not delete or replace that slot

#### Scenario: One-off slot blocks overlapping candidate
- **WHEN** a one-off open slot overlaps a generated candidate interval
- **THEN** the generator skips creating that candidate

### Requirement: Existing open-slot non-overlap invariant still holds
Generated and one-off open slots for the same coach MUST continue to obey the half-open non-overlap rule. Generation MUST skip candidates that would violate it rather than leaving the coach calendar in an overlapping open state.

#### Scenario: Overlapping candidate skipped
- **WHEN** a generate candidate overlaps any existing slot of the coach
- **THEN** that candidate is not inserted as an open slot

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
Materializing an occurrence MUST prefer booking an existing matching open ScheduleSlot and create a Session. Matching MUST use absolute UTC bounds derived from local wall time via the series timezone. Pending holds, non-open exact slots, mode mismatches, and non-exact overlaps MUST block materialization and surface as conflicts.

When no matching slot exists and no open or booked slot overlaps the occurrence interval, materialization MUST create a one-off ScheduleSlot (`seriesId` null) with those exact bounds and book it atomically rather than reporting `missing_slot`. Materialization MUST NOT create a second slot on top of an exact slot that exists with a different mode.

#### Scenario: Exact open slot booked
- **WHEN** an occurrence needs 18:00–19:00 local and a matching open unheld slot exists
- **THEN** that slot is booked into a Session for the series student

#### Scenario: Exact open slot required when only partial overlap exists
- **WHEN** an occurrence needs 18:00–19:00 local and only a 17:30–18:30 open slot exists
- **THEN** the occurrence is a conflict (`overlap`) rather than a partial or shifted automatic book

#### Scenario: Missing interval is created on demand
- **WHEN** an occurrence has no exact slot and no overlapping open or booked slot
- **THEN** a one-off booked slot and Session are created for that interval

### Requirement: Partial conflicts do not roll back successful books
When some occurrences can be booked and others cannot, the domain MUST keep successful Sessions and expose unresolved conflicts for coach resolution. Conflict reasons MUST distinguish at least: missing-or-created path is no longer a residual conflict after success; held slot; unavailable/booked slot; non-exact overlap; and mode mismatch.

#### Scenario: Mixed week result
- **WHEN** two of three weekly occurrences have free slots and one overlaps an existing booked appointment
- **THEN** two Sessions exist and one conflict remains for coach action

### Requirement: Cancelling a series stops future appointments
Cancelling a RecurringBooking MUST prevent further materialization and MUST terminate future `booked` Sessions of that series through the normal session lifecycle. Historical terminal Sessions remain unchanged.

#### Scenario: Future booked cancelled with series
- **WHEN** an active series with a future booked Session is cancelled
- **THEN** that future Session transitions to cancelled and no new Sessions are created for the series

### Requirement: Coach may book a linked student at an arbitrary free interval
The calendar domain SHALL allow a coach to create an appointment for a linked student at an absolute time range without a pre-existing open ScheduleSlot. The operation MUST atomically create a ScheduleSlot with `seriesId` null, create the Session (`createdBy=coach`) with charge, and leave the slot in status `booked`. The interval MUST NOT overlap any open, booked, or blocked slot of the coach.

#### Scenario: Book without prior availability
- **WHEN** a coach books a linked student at an interval with no existing slot
- **THEN** a booked Session and a booked ScheduleSlot exist for that interval and no open slot was exposed for student requests

#### Scenario: Overlap blocks book-at-time
- **WHEN** a coach books a linked student at an interval overlapping an existing booked Session slot
- **THEN** the domain rejects the operation and leaves the calendar unchanged
