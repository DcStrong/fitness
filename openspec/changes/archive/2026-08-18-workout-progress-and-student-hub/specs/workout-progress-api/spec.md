## ADDED Requirements

### Requirement: Completing a session can store actual set logs
The system SHALL persist actual set logs for a completed session when the coach submits them on complete. Each log row MUST store `exerciseId`, set order, and the performed `reps` / `weightKg` / `durationSeconds`. If complete is called with no logs and the session has an attached student plan, the system MUST snapshot the current prescription as actual logs. If there is no plan and no logs, complete MUST still succeed with zero log rows. Logs MUST NOT be written on cancel or no_show. After complete, logs MUST NOT be mutated via this API.

#### Scenario: Complete with explicit logs
- **WHEN** the coach completes a booked session with log payload matching attached exercises
- **THEN** the session is `completed` and those actual sets are stored

#### Scenario: Complete without logs copies prescription
- **WHEN** the coach completes a booked session that has an attached plan and omits logs
- **THEN** the session is `completed` and log rows equal the plan's current sets

#### Scenario: Complete without plan or logs
- **WHEN** the coach completes a booked session with no plan and no logs
- **THEN** the session is `completed` and no set logs exist

#### Scenario: Cancel writes no logs
- **WHEN** a booked session is cancelled
- **THEN** no set logs are stored for that session

### Requirement: Coach and student can read progress series for an exercise
The system SHALL expose a progress series for a student and exercise as points `{ sessionId, completedAt, weightKg, volume }` derived from completed session logs. The session coach of an active link and the student themselves MAY read. Volume MUST be the session sum of `reps * weightKg` for that exercise. `weightKg` on a point MUST be the heaviest logged set that session.

#### Scenario: Series after two completed sessions
- **WHEN** a student has two completed sessions with logs for the same exercise
- **THEN** progress returns two points ordered by completed time with weight and volume

#### Scenario: Outsider denied
- **WHEN** a user who is not the linked coach or the student requests progress
- **THEN** the system rejects the request
