# session-lifecycle Specification

## Purpose
Explicit session status transitions from `booked` to terminal states (`completed`, `cancelled`, `no_show`), with participant and permission checks. Cancel does not reopen the schedule slot in MVP.
## Requirements
### Requirement: Booked session can be completed by coach
The system SHALL allow a user with `sessions:complete` who is the session's coach to transition a session from `booked` to `completed`. Any other from-status MUST be rejected. Complete MAY include optional actual set logs; omitting logs MUST NOT block the transition.

#### Scenario: Coach completes booked session
- **WHEN** the coach of a `booked` session calls complete
- **THEN** the session status becomes `completed`

#### Scenario: Complete from non-booked rejected
- **WHEN** complete is called on a session that is not `booked`
- **THEN** the system rejects the request

#### Scenario: Non-coach cannot complete
- **WHEN** a user who is not the session coach calls complete
- **THEN** the system rejects the request as forbidden

### Requirement: Complete may include actual set logs
When completing a booked session the coach MAY submit actual set logs in the same request. Behavior of log persistence MUST follow workout-progress-api. Complete without logs MUST remain valid.

#### Scenario: Coach completes with logs
- **WHEN** the coach of a `booked` session calls complete with a logs payload
- **THEN** the session status becomes `completed` and the logs are stored in the same transaction

### Requirement: Booked session can be cancelled by coach or student
The system SHALL allow a user with `sessions:cancel` who is the session's coach or student to transition a session from `booked` to `cancelled`. Optional `note` MAY be stored on the history event.

#### Scenario: Student cancels own booked session
- **WHEN** the student of a `booked` session calls cancel
- **THEN** the session status becomes `cancelled`

#### Scenario: Coach cancels booked session
- **WHEN** the coach of a `booked` session calls cancel
- **THEN** the session status becomes `cancelled`

### Requirement: Booked session can be marked no_show by coach
The system SHALL allow a user with `sessions:mark_no_show` who is the session's coach to transition a session from `booked` to `no_show`. The request MUST include an explicit `charge` decision. If chargeable, the Session charge becomes earned; otherwise it becomes cancelled.

#### Scenario: Coach marks no_show
- **WHEN** the coach of a `booked` Session calls no-show with an explicit `charge` decision
- **THEN** the Session status becomes `no_show` and its charge follows that decision

#### Scenario: Coach marks chargeable no_show
- **WHEN** the coach marks a booked Session no-show with `charge: true`
- **THEN** the Session status becomes `no_show` and its pending charge receives `earnedAt`

#### Scenario: Coach marks non-chargeable no_show
- **WHEN** the coach marks a booked Session no-show with `charge: false`
- **THEN** the Session status becomes `no_show` and its charge becomes cancelled

#### Scenario: No-show billing decision omitted
- **WHEN** no-show is requested without an explicit charge decision
- **THEN** the system rejects the request

### Requirement: Cancel does not reopen schedule slot in this change
When a session is cancelled, the system MUST NOT automatically set the linked schedule slot status back to `open` in this change.

#### Scenario: Slot remains booked after cancel
- **WHEN** a session linked to a schedule slot is cancelled
- **THEN** the schedule slot status remains `booked` (or otherwise not reopened by this flow)

### Requirement: Completed session becomes financially earned
Completing a tracked booked Session SHALL atomically set its pending charge `earnedAt`. Completion MUST NOT mark it paid.

#### Scenario: Complete tracked session
- **WHEN** the coach completes a tracked booked Session
- **THEN** Session status and charge earned state commit together while payment remains pending

### Requirement: Cancelled session charge is cancelled
Cancelling a tracked booked Session SHALL atomically cancel its unearned pending charge. It MUST NOT contribute to accrued, received, or outstanding totals.

#### Scenario: Cancel tracked booked session
- **WHEN** a participant cancels a tracked booked Session
- **THEN** Session and charge become cancelled in the same transaction

### Requirement: Session lifecycle debits session package when applicable
In addition to existing charge and history behavior, transitioning a Session from `booked` to `completed`, or to `no_show` with a chargeable decision, SHALL trigger at most one SessionPackage debit for the coach–student pair per the session-packages rules. Cancel and non-chargeable no_show MUST NOT debit a package. Package absence MUST NOT block the lifecycle transition.

#### Scenario: Complete still succeeds without package
- **WHEN** a coach completes a Session for a student with no session package
- **THEN** the Session becomes `completed` and no package debit occurs

#### Scenario: Complete debits package when present
- **WHEN** a coach completes a Session and an active package exists for that pair
- **THEN** the Session becomes `completed` and the package remaining decreases by one subject to package rules

#### Scenario: Cancel does not debit package
- **WHEN** a coach or student cancels a booked Session
- **THEN** the Session becomes `cancelled` and package remaining is unchanged

