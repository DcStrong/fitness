## ADDED Requirements

### Requirement: Complete may include actual set logs
When completing a booked session the coach MAY submit actual set logs in the same request. Behavior of log persistence MUST follow workout-progress-api. Complete without logs MUST remain valid.

#### Scenario: Coach completes with logs
- **WHEN** the coach of a `booked` session calls complete with a logs payload
- **THEN** the session status becomes `completed` and the logs are stored in the same transaction

## MODIFIED Requirements

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
