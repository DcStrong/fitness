## MODIFIED Requirements

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

## ADDED Requirements

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
