## MODIFIED Requirements

### Requirement: Trainer can book a session for a linked student
The system SHALL allow a user with `sessions:book_for_student` to create a `booked` session for one of their linked students. The request MUST supply exactly one of: (a) an existing own open `scheduleSlotId`, or (b) an absolute time range `startsAt`/`endsAt` with optional `mode` (`online` | `offline`, default `offline`). For (b) the system MUST atomically create a ScheduleSlot (`seriesId` null), create the Session with charge, and mark the slot `booked` without leaving a publicly bookable open slot. `createdBy` MUST be coach. Overlap with any existing `open` or `booked` slot of the coach MUST be rejected.

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
- **WHEN** a trainer submits a time range that overlaps an existing open or booked slot of the same coach
- **THEN** the system rejects the request with a conflict-style error and creates neither Session nor slot

#### Scenario: Both scheduleSlotId and time range rejected
- **WHEN** a trainer submits both `scheduleSlotId` and `startsAt`/`endsAt` in one request
- **THEN** the system rejects the request as invalid

## ADDED Requirements

### Requirement: Book-at-time is atomic with coach lock
Coach book-at-time MUST run under the same coach-row pessimistic lock pattern as existing slot booking so concurrent create/book operations cannot leave an open orphan slot or double-book the interval.

#### Scenario: Concurrent book-at-time on same interval
- **WHEN** two coach book-at-time operations target the same overlapping interval concurrently
- **THEN** exactly one succeeds and the other fails without an orphan open slot
