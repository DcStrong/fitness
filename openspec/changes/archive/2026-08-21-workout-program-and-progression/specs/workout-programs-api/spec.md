## ADDED Requirements

### Requirement: Coach can upsert a workout program on an owned recurring booking
The system SHALL allow the owning coach with `sessions:book_for_student` to create or replace a workout program for an active RecurringBooking. The program MUST map each included weekday to an ordered list of the coach's `kind=template` plans. Every weekday in the program MUST be a weekday of the series. For each template the system MUST idempotently assign a `kind=student_copy` to the series student. Empty day lists MUST be rejected. `horizonWeeks` MUST be an integer from 1 to 8 inclusive (default 2). Upsert MUST run in one transaction and MUST apply snapshots to future booked sessions of the series within the horizon.

#### Scenario: Program for Mon and Saturday
- **WHEN** a coach PUTs a program with weekday 1 → template «Силовая» and weekday 6 → template «Силовая» on a Mon/Thu/Sat series
- **THEN** the program is stored, a student copy exists for «Силовая», and upcoming Monday and Saturday booked sessions in the horizon receive that workout

#### Scenario: Weekday not in series rejected
- **WHEN** a coach includes weekday 2 on a series that has only weekdays 1, 4, and 6
- **THEN** the system rejects the request and writes no program rows

#### Scenario: Unowned series rejected
- **WHEN** another coach PUTs a program on the series
- **THEN** the system rejects the request

### Requirement: Program day can list multiple templates
The system SHALL persist two or more templates on the same weekday as ordered program day items. Apply MUST attach the corresponding student copies to each matching session in that order.

#### Scenario: Two workouts on Thursday
- **WHEN** the coach sets Thursday to templates «Ноги» then «Кор»
- **THEN** Thursday sessions in the horizon have two workout items in that order

### Requirement: Coach can set per-exercise weight progression on a program
The system SHALL store optional progression rules keyed by `exerciseId` on the program: `startWeightKg`, `deltaKg`, and `incrementKg` (default 2.5). A missing rule or `deltaKg` of 0 MUST leave snapshot weights equal to the student copy for that exercise. When `deltaKg` is non-zero, apply MUST interpolate linearly across chronological occurrences of that exercise in the horizon so the first occurrence uses `startWeightKg` and the last uses `startWeightKg + deltaKg`, rounding to `incrementKg`, and MUST write those weights onto session prescription snapshots without requiring the coach to PATCH each session.

#### Scenario: Plus five kilos over two weeks
- **WHEN** bench press appears on Mon and Sat, horizon is 2 weeks, start is 80, delta is 5, increment is 2.5
- **THEN** the last occurrence in the horizon is snapshotted at 85 kg and earlier occurrences are interpolated toward that target

#### Scenario: No delta keeps copy weights
- **WHEN** a program exercise has no progression rule
- **THEN** session snapshots use the student copy's current weights for that exercise

### Requirement: Apply fills future sessions and skips overrides and completed sessions
The system SHALL apply a program onto the series' future `booked` sessions inside the horizon. Sessions that are completed, cancelled, or no-show MUST NOT be modified. Sessions whose workout list was manually overridden MUST NOT be modified unless the caller requests force apply. Recurring booking sync MUST apply the program to newly created booked sessions.

#### Scenario: New sync session gets program
- **WHEN** recurring sync books a new Monday session and a program maps Monday to «Силовая»
- **THEN** that session has the program's workout items and a prescription snapshot

#### Scenario: Overridden session skipped
- **WHEN** the coach changed that session's workouts and apply runs without force
- **THEN** that session's workouts and snapshot stay as overridden

### Requirement: Successful completes can roll the horizon; a miss holds that lift
When a series session with a program is completed, the system SHALL compare actual max weight per progressed exercise to the session snapshot. If actual is greater than or equal to prescribed, the system MUST treat that lift as on-plan. If every progressed lift that appeared in the snapshot is on-plan and less than one week of horizon remains, the system MUST extend by applying a new window using the latest successful weight as `startWeightKg` with the same `deltaKg` and `horizonWeeks`, and MUST update the student copy start weights accordingly. If a lift misses, the system MUST hold that lift's future snapshots in the current horizon at the actual max and MUST NOT apply further delta for that lift until the coach upserts the rule or requests continue-progression apply. Other lifts MUST keep their curves.

#### Scenario: On-plan complete near horizon end extends
- **WHEN** the last week of the horizon completes with actual bench at or above prescribed
- **THEN** the next horizon window is materialized with start equal to that successful weight and the same delta

#### Scenario: Miss holds bench only
- **WHEN** Thursday legs hit prescribed weights but Monday bench actual is below snapshot
- **THEN** future bench snapshots stay at the missed actual and leg progression continues
