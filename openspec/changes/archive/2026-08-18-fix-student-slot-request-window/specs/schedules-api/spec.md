## MODIFIED Requirements

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
