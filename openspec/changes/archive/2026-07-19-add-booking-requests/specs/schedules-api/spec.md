## MODIFIED Requirements

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
The system SHALL allow a student with `schedules:read_linked` to list requestable availability slots for a coach they are linked to via an active coach–student relationship. Results MUST include only future/current `open` slots without a non-expired pending BookingRequest.

#### Scenario: Linked student sees requestable coach slots
- **WHEN** a linked student requests slots for their coach
- **THEN** free unheld slots for that coach are returned

#### Scenario: Held slot is hidden
- **WHEN** another student has a non-expired pending request for an otherwise open slot
- **THEN** that slot is omitted from linked-coach availability

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
