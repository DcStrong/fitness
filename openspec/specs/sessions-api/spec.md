# sessions-api Specification

## Purpose
HTTP API for booking sessions from open slots, listing the caller's appointments (optional status filter), and lifecycle transitions with history.
## Requirements
### Requirement: Accepted booking request creates a booked session
The system SHALL create a `booked` Session only when a coach accepts a valid pending BookingRequest at the requested slot or an alternate one-off slot. The Session MUST reference the resolved slot, snapshot its time/mode, use `createdBy=coach`, and reference the accepted request through its response/audit relation.

#### Scenario: Requested slot accepted
- **WHEN** a coach accepts a pending request at the requested slot
- **THEN** one booked Session is created from that slot and returned through normal own-session reads

#### Scenario: Alternate slot accepted
- **WHEN** a coach resolves a pending request at another conflict-free time
- **THEN** one booked Session is created from the new one-off slot

#### Scenario: Student calls direct booking endpoint
- **WHEN** a student attempts to create a Session directly
- **THEN** the system rejects the request with an actionable error directing the client to BookingRequests

### Requirement: Trainer can book a session for a linked student
The system SHALL allow a user with `sessions:book_for_student` to create a `booked` session for one of their linked students. The request MUST supply exactly one of: (a) an existing own open `scheduleSlotId`, or (b) an absolute time range `startsAt`/`endsAt` with optional `mode` (`online` | `offline`, default `offline`). For (b) the system MUST atomically create a ScheduleSlot (`seriesId` null), create the Session with charge, and mark the slot `booked` without leaving a publicly bookable open slot. `createdBy` MUST be coach. Overlap with any existing `open`, `booked`, or `blocked` slot of the coach MUST be rejected.

#### Scenario: Coach books for linked student
- **WHEN** a trainer books their free slot for a linked student
- **THEN** a `booked` session is created with that student and `createdBy` = coach

#### Scenario: Coach books unlinked student rejected
- **WHEN** a trainer books for a user who is not linked as their student
- **THEN** the system rejects the request

#### Scenario: Coach books at time without existing slot
- **WHEN** a trainer submits `startsAt`/`endsAt`/`mode` and a linked `studentId` with no prior open slot at that interval
- **THEN** the system creates a booked Session and a matching ScheduleSlot already in status `booked`

#### Scenario: Coach book-at-time overlaps existing appointment
- **WHEN** a trainer submits a time range that overlaps an existing open, booked, or blocked slot of the same coach
- **THEN** the system rejects the request with a conflict-style error and creates neither Session nor slot

#### Scenario: Both scheduleSlotId and time range rejected
- **WHEN** a trainer submits both `scheduleSlotId` and `startsAt`/`endsAt` in one request
- **THEN** the system rejects the request as invalid

### Requirement: Users can list their sessions
The system SHALL allow users with `sessions:read_own` to list sessions where they are the coach or the student.

#### Scenario: Student sees own bookings
- **WHEN** a student lists sessions
- **THEN** sessions where they are the student are returned

#### Scenario: Coach sees own sessions
- **WHEN** a coach lists sessions
- **THEN** sessions where they are the coach are returned

### Requirement: Optional status filter on session list
The system SHALL allow `GET /sessions` callers with `sessions:read_own` to optionally filter by session status (e.g. query `status=booked` or multiple values as defined by the API).

#### Scenario: Filter booked only
- **WHEN** a user lists sessions with status filter `booked`
- **THEN** only sessions with status `booked` where they are coach or student are returned

### Requirement: New sessions start as booked
Sessions created via booking MUST start as `booked`. Further status changes follow `session-lifecycle` requirements.

#### Scenario: New session is booked
- **WHEN** a booking succeeds
- **THEN** session.status equals `booked`

### Requirement: Booking atomically creates financial snapshot
A successful direct coach booking or accepted BookingRequest SHALL atomically create its Session charge. Direct coach booking SHALL use the configured default or allowed one-session override; request acceptance SHALL use the immutable quoted amount/currency stored on the BookingRequest.

#### Scenario: Request acceptance and charge commit together
- **WHEN** BookingRequest acceptance succeeds
- **THEN** request status, Session, resolved slot status, and one pending charge using the quote are committed in the same transaction

#### Scenario: Direct coach booking and charge commit together
- **WHEN** trainer book-for-student succeeds
- **THEN** Session, slot status, and one pending charge with the applicable price snapshot are committed in the same transaction

#### Scenario: Charge creation fails
- **WHEN** charge persistence fails during direct booking or request acceptance
- **THEN** neither Session creation, slot booking, nor request acceptance is committed

### Requirement: Session responses include scoped finance summary
Session responses SHALL include a finance summary with amount, currency, and charge status for participants allowed to read that charge. Legacy Sessions without a charge SHALL return `not_tracked`.

#### Scenario: Participant lists tracked Session
- **WHEN** the coach or student lists their tracked Sessions
- **THEN** each Session includes its own price and payment status

#### Scenario: Legacy Session listed
- **WHEN** a participant lists a Session created before finance tracking
- **THEN** its finance state is `not_tracked` rather than a fabricated zero price

### Requirement: Recurring materialization creates coach-booked sessions
When recurring-booking sync books an occurrence, the system SHALL create a Session with status `booked`, `createdBy=coach`, the linked student, the matched schedule slot snapshot (time/mode), and SHALL create the Session charge atomically using the same quoting rules as direct book-for-student. The Session MUST store references to the RecurringBooking and occurrence local date for idempotency.

#### Scenario: Charge created with recurring session
- **WHEN** recurring sync successfully books an open slot for a student
- **THEN** a booked Session and its charge exist exactly as for trainer book-for-student

#### Scenario: Idempotent by occurrence date
- **WHEN** a Session already exists for the same recurring booking and local date
- **THEN** sync does not create a second Session for that occurrence

### Requirement: Recurring cancellation uses session lifecycle for future booked rows
When a RecurringBooking is cancelled, the system SHALL cancel each future Session of that series that is still `booked` using the existing cancel lifecycle transition and history audit. Sessions in terminal states MUST NOT be modified.

#### Scenario: Only future booked are cancelled
- **WHEN** a series is cancelled and it has one completed past Session and one future booked Session
- **THEN** the completed Session stays completed and the future Session becomes cancelled

### Requirement: Book-at-time is atomic with coach lock
Coach book-at-time MUST run under the same coach-row pessimistic lock pattern as existing slot booking so concurrent create/book operations cannot leave an open orphan slot or double-book the interval.

#### Scenario: Concurrent book-at-time on same interval
- **WHEN** two coach book-at-time operations target the same overlapping interval concurrently
- **THEN** exactly one succeeds and the other fails without an orphan open slot

### Requirement: Session can reference an assigned student workout
The system SHALL store an ordered list of workout items on a Session, each pointing at a `kind=student_copy` owned by the session coach and assigned to the session student. GET session responses for participants MUST include `workouts` (id, title, goal, tags, exercises, source, overridden) and MUST still include `studentPlanId` as the first item's plan id or null when the list is empty. A user with `sessions:book_for_student` who is the session coach MAY PATCH `workoutPlanIds` (ordered uuid array; empty detaches all) or PATCH `studentPlanId` as a single-item shorthand. Foreign or template-kind ids without a matching copy MUST be rejected. Setting workouts manually MUST mark the session as overridden so program apply without force MUST NOT replace them.

#### Scenario: Attach copy to session
- **WHEN** the coach PATCHes a booked session with a student copy for that student
- **THEN** subsequent GET returns that `studentPlanId`, a one-element `workouts` list, and plan summary

#### Scenario: Attach two copies
- **WHEN** the coach PATCHes `workoutPlanIds` with two student copies of that student
- **THEN** GET returns both in order and `studentPlanId` equals the first

#### Scenario: Wrong student's copy rejected
- **WHEN** the coach attaches a copy assigned to a different student
- **THEN** the system rejects the request

#### Scenario: Detach
- **WHEN** the coach PATCHes `studentPlanId` null or `workoutPlanIds` empty
- **THEN** the session has no linked plans and lifecycle remains available

#### Scenario: Student cannot attach
- **WHEN** the student PATCHes `studentPlanId` or `workoutPlanIds`
- **THEN** the system rejects the request

### Requirement: Session stores a prescription snapshot for attached workouts
The system SHALL persist set prescription snapshots for each session workout item (exercise, order, reps, weightKg, durationSeconds) when workouts are attached by program apply or by coach PATCH. GET session MUST return snapshot sets as the workout content for that date. Completing the session without explicit logs MUST copy the snapshot, not the live student copy, into actual logs when logs exist in the product.

#### Scenario: Snapshot differs from later copy edit
- **WHEN** a Monday session was snapshotted at 80 kg and the coach later sets the copy start to 90 kg without force-applying that session
- **THEN** GET of that Monday session still shows 80 kg

#### Scenario: Complete uses snapshot
- **WHEN** the coach completes a booked session with no log payload and snapshots exist
- **THEN** stored actual logs match the snapshot sets
