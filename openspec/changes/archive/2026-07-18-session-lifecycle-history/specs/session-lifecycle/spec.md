## ADDED Requirements

### Requirement: Booked session can be completed by coach
The system SHALL allow a user with `sessions:complete` who is the session's coach to transition a session from `booked` to `completed`. Any other from-status MUST be rejected.

#### Scenario: Coach completes booked session
- **WHEN** the coach of a `booked` session calls complete
- **THEN** the session status becomes `completed`

#### Scenario: Complete from non-booked rejected
- **WHEN** complete is called on a session that is not `booked`
- **THEN** the system rejects the request

#### Scenario: Non-coach cannot complete
- **WHEN** a user who is not the session coach calls complete
- **THEN** the system rejects the request as forbidden

### Requirement: Booked session can be cancelled by coach or student
The system SHALL allow a user with `sessions:cancel` who is the session's coach or student to transition a session from `booked` to `cancelled`. Optional `note` MAY be stored on the history event.

#### Scenario: Student cancels own booked session
- **WHEN** the student of a `booked` session calls cancel
- **THEN** the session status becomes `cancelled`

#### Scenario: Coach cancels booked session
- **WHEN** the coach of a `booked` session calls cancel
- **THEN** the session status becomes `cancelled`

### Requirement: Booked session can be marked no_show by coach
The system SHALL allow a user with `sessions:mark_no_show` who is the session's coach to transition a session from `booked` to `no_show`.

#### Scenario: Coach marks no_show
- **WHEN** the coach of a `booked` session calls no-show
- **THEN** the session status becomes `no_show`

### Requirement: Cancel does not reopen schedule slot in this change
When a session is cancelled, the system MUST NOT automatically set the linked schedule slot status back to `open` in this change.

#### Scenario: Slot remains booked after cancel
- **WHEN** a session linked to a schedule slot is cancelled
- **THEN** the schedule slot status remains `booked` (or otherwise not reopened by this flow)
