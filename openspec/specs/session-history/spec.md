# session-history Specification

## Purpose
Append-only history events for successful session lifecycle transitions; participants can read the timeline for a session.
## Requirements
### Requirement: Status transitions append history events
The system SHALL, in the same transaction as a successful lifecycle transition, append a history event recording `sessionId`, `actorUserId`, `fromStatus`, `toStatus`, optional `note`, and `createdAt`.

#### Scenario: Complete writes history
- **WHEN** a session is successfully completed
- **THEN** a history event exists with fromStatus `booked` and toStatus `completed`

#### Scenario: Failed transition writes no history
- **WHEN** a transition is rejected
- **THEN** no new history event is created for that attempt

### Requirement: Participants can read session history
The system SHALL allow a user with `sessions:read_history` who is the session's coach or student to list history events for that session in chronological order.

#### Scenario: Coach reads history
- **WHEN** the coach requests history for their session
- **THEN** events for that session are returned ordered by createdAt ascending

#### Scenario: Outsider denied
- **WHEN** a user who is neither coach nor student requests history
- **THEN** the system rejects the request as forbidden
