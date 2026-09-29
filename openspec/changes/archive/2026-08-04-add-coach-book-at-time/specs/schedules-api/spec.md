## MODIFIED Requirements

### Requirement: Trainer can create availability slots
The system SHALL allow a user with `schedules:create` to create **open** availability slots for themselves as coach. Each slot MUST have `startsAt`, `endsAt` (`endsAt` > `startsAt`), and optional `mode` (`online` | `offline`, default `offline`). The slot MUST NOT overlap another `open` or `booked` slot of the same coach (half-open `[startsAt, endsAt)`).

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
