## ADDED Requirements

### Requirement: Trainer can create availability slots
The system SHALL allow a user with `schedules:create` to create **open** availability slots for themselves as coach. Each slot MUST have `startsAt`, `endsAt` (`endsAt` > `startsAt`), and optional `mode` (`online` | `offline`, default `offline`). The slot MUST NOT overlap another open slot of the same coach.

#### Scenario: Successful slot create
- **WHEN** a trainer creates a valid non-overlapping future (or current) open slot
- **THEN** the system stores the slot owned by that coach with status `open` and returns it

#### Scenario: Invalid time range rejected
- **WHEN** `endsAt` is not after `startsAt`
- **THEN** the system rejects the request

#### Scenario: Overlapping open slot rejected
- **WHEN** the new open slot overlaps an existing open slot of the same coach
- **THEN** the system rejects the request

### Requirement: Trainer can list and remove own slots
The system SHALL allow a coach with `schedules:read_own` / `schedules:delete_own` to list and soft-delete or hard-delete their own unused slots.

#### Scenario: List own slots
- **WHEN** a trainer lists schedule slots
- **THEN** only slots where coachId equals the caller are returned

#### Scenario: Delete own free slot
- **WHEN** a trainer deletes an own slot that is not booked
- **THEN** the slot is no longer available for booking

### Requirement: Student can list linked coach availability
The system SHALL allow a student with `schedules:read_linked` to list availability slots for a coach they are linked to via an active coach–student relationship.

#### Scenario: Linked student sees coach slots
- **WHEN** a linked student requests slots for their coach
- **THEN** free (unbooked) slots for that coach are returned

#### Scenario: Unlinked student denied
- **WHEN** a student requests slots for a coach without an active link
- **THEN** the system rejects the request as forbidden
