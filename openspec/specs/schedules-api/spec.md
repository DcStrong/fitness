# schedules-api Specification

## Purpose
HTTP API for coach availability slots: create, list own, delete open, and list linked coach open slots for students.
## Requirements
### Requirement: Trainer can create availability slots
The system SHALL allow a user with `schedules:create` to create **open** availability slots for themselves as coach. Each slot MUST have `startsAt`, `endsAt` (`endsAt` > `startsAt`), and optional `mode` (`online` | `offline`, default `offline`). The slot MUST NOT overlap another `open`, `booked`, or `blocked` slot of the same coach (half-open `[startsAt, endsAt)`).

#### Scenario: Successful slot create
- **WHEN** a trainer creates a valid non-overlapping future (or current) open slot
- **THEN** the system stores the slot owned by that coach with status `open` and returns it

#### Scenario: Invalid time range rejected
- **WHEN** `endsAt` is not after `startsAt`
- **THEN** the system rejects the request

#### Scenario: Overlapping open slot rejected
- **WHEN** the new open slot overlaps an existing open slot of the same coach
- **THEN** the system rejects the request

#### Scenario: Overlapping booked slot rejected
- **WHEN** the new open slot overlaps an existing booked slot of the same coach
- **THEN** the system rejects the request

### Requirement: Trainer can list and remove own slots
The system SHALL allow a coach with `schedules:read_own` / `schedules:delete_own` to list their own slots. It SHALL allow deletion only when the slot is open, unbooked, and has no non-expired pending BookingRequest.

#### Scenario: List own slots
- **WHEN** a trainer lists schedule slots
- **THEN** only slots where coachId equals the caller are returned and held state is available for trainer UI

#### Scenario: Delete own free slot
- **WHEN** a trainer deletes an own open slot without a pending request
- **THEN** the slot is no longer available for booking

#### Scenario: Delete held slot rejected
- **WHEN** a trainer attempts to delete an open slot with a non-expired pending request
- **THEN** the system rejects deletion with a conflict response

### Requirement: Student can list linked coach availability
The system SHALL allow a student with `schedules:read_linked` to list requestable availability slots for a coach they are linked to via an active coach–student relationship. Results MUST include only `open` slots without a non-expired pending BookingRequest **and** whose booking-request decision window is still open: slot `startsAt` MUST be strictly later than `now + 2 hours` (the same cutoff used when creating a BookingRequest). In-progress slots (`startsAt <= now`) MUST NOT be returned as requestable. If the caller supplies a `from` earlier than that cutoff, the system MUST still apply the cutoff.

#### Scenario: Linked student sees requestable coach slots
- **WHEN** a linked student requests slots for their coach
- **THEN** free unheld slots for that coach whose start is more than two hours from now are returned

#### Scenario: Held slot is hidden
- **WHEN** another student has a non-expired pending request for an otherwise open slot
- **THEN** that slot is omitted from linked-coach availability

#### Scenario: Slot inside the two-hour cutoff is hidden
- **WHEN** a linked student lists requestable slots and an otherwise open unheld slot starts at or before `now + 2 hours`
- **THEN** that slot is omitted from the response

#### Scenario: In-progress slot is hidden
- **WHEN** a linked student lists requestable slots and an otherwise open slot has already started but has not ended
- **THEN** that slot is omitted from the response

#### Scenario: Unlinked student denied
- **WHEN** a student requests slots for a coach without an active link
- **THEN** the system rejects the request as forbidden

### Requirement: Linked student sees coach session price before booking
Requestable-slot responses for a linked coach SHALL include the coach's current positive default session price and currency when finance settings are configured. That price is the quote to be snapshotted if the student creates a BookingRequest.

#### Scenario: Price displayed with requestable slot
- **WHEN** a linked student lists an unheld open slot and the coach configured finance settings
- **THEN** the response provides the price/currency that request creation will snapshot

#### Scenario: Coach has no configured price
- **WHEN** a linked student lists slots for a coach without finance settings
- **THEN** the response indicates price is not configured and a BookingRequest cannot be created

### Requirement: Trainer can read and update schedule settings via API
The schedules API SHALL expose authenticated coach endpoints to get and upsert own schedule settings (timezone, durations, break, horizon, default mode). Callers MUST hold existing schedule own-read / create-style permissions already used for slot management. Responses MUST NOT include finance price fields.

#### Scenario: Get settings
- **WHEN** a coach with schedule read permission requests availability settings
- **THEN** the API returns the stored settings or sensible defaults/empty state for first-time setup

#### Scenario: Put settings
- **WHEN** a coach upserts valid settings
- **THEN** the API persists them and returns the saved representation

### Requirement: Trainer can read and update weekly template via API
The schedules API SHALL expose endpoints to get and upsert the coach's weekly availability template (series identity and weekday windows). Invalid overlapping windows or invalid time bounds MUST be rejected. Upsert MUST be scoped to the authenticated coach.

#### Scenario: Upsert template
- **WHEN** a coach puts a valid Monday–Sunday window set
- **THEN** the API stores the template for that coach and subsequent GET returns the same windows and series id

#### Scenario: Foreign template denied
- **WHEN** a caller attempts to modify another coach's template
- **THEN** the API rejects the request as forbidden or not found without leaking data

### Requirement: Trainer can manage date exceptions via API
The schedules API SHALL allow a coach to list and replace (or create/update/delete) availability exceptions for local dates: closed or custom hours. Exception payloads MUST be validated like template windows.

#### Scenario: Replace exceptions
- **WHEN** a coach submits a valid set of exceptions including one closed date and one custom-hours date
- **THEN** the API stores that set for the coach series and returns it on list

### Requirement: Trainer can generate slots from the template
The schedules API SHALL provide a generate operation that materializes open slots for the configured horizon using fixed-grid rules from calendar-domain. The operation MUST be idempotent, MUST use a coach-scoped lock/transaction consistent with booking mutations, and MUST return a summary of created/skipped/(optional) removed counts. Existing `POST /schedule/slots`, `GET /schedule/slots`, `DELETE /schedule/slots/:id` and linked-coach slot listing MUST remain backward compatible.

#### Scenario: Generate creates open slots
- **WHEN** a coach with a valid template and settings calls generate
- **THEN** open slots appear in `GET /schedule/slots` within the horizon and carry the template series id

#### Scenario: Generate respects holds and bookings
- **WHEN** generate runs while some series intervals are booked or held by pending requests
- **THEN** those intervals are left intact and conflicting candidates are skipped

#### Scenario: List own slots remains compatible
- **WHEN** a client lists own slots with optional `from` and `to` after generation
- **THEN** both one-off and generated slots in range are returned without requiring new query parameters

### Requirement: Optional preview does not persist slots
If the API exposes a preview endpoint, it SHALL return the candidate intervals that generate would create for a range without inserting rows. Preview MUST use the same fixed-grid rules as generate.

#### Scenario: Preview without side effects
- **WHEN** a coach requests availability preview for a date range
- **THEN** the response lists candidate starts/ends and no new `ScheduleSlot` rows are persisted

