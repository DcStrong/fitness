## ADDED Requirements

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
