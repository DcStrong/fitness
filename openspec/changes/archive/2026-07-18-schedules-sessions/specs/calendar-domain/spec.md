## ADDED Requirements

### Requirement: Calendar separates availability from appointments
The backend calendar SHALL model bookable availability (`ScheduleSlot`) separately from appointments (`Session`). Booking SHALL create a Session and mark the corresponding availability slot as no longer open. Session times MUST be snapshotted from the slot at booking time.

#### Scenario: Book converts open slot into booked session
- **WHEN** a valid booking is made against an open slot
- **THEN** a Session exists with status `booked` and the slot is no longer open for another booking

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
Booking SHALL run as a server-side atomic operation such that two concurrent booking attempts on the same open slot cannot both succeed.

#### Scenario: Concurrent book of same slot
- **WHEN** two booking requests target the same open slot concurrently
- **THEN** exactly one succeeds and the other fails with a conflict-style error

### Requirement: Schema reserves extension points without requiring MVP features
The persistence model SHALL allow future recurrence, gym, and capacity/groups without renaming the core Slot/Session concepts (for example nullable `seriesId`/`gymId`, `capacity` defaulting to 1, and session status values that include future lifecycle states even if only `booked` is writable now).

#### Scenario: MVP writes only booked status
- **WHEN** a booking succeeds in this change
- **THEN** the created session status is `booked` and complete/cancel transitions are not exposed yet
