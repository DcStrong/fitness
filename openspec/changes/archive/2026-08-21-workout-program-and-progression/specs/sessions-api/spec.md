## MODIFIED Requirements

### Requirement: Session can reference an assigned student workout
The system SHALL store an ordered list of workout items on a Session, each pointing at a `kind=student_copy` owned by the session coach and assigned to the session student. GET session responses for participants MUST include `workouts` (id, title, goal, tags, exercises, source, overridden) and MUST still include `studentPlanId` as the first item's plan id or null when the list is empty. A user with `sessions:book_for_student` who is the session coach MAY PATCH `workoutPlanIds` (ordered uuid array; empty detaches all) or PATCH `studentPlanId` as a single-item shorthand. Foreign or template-kind ids without a matching copy MUST be rejected. Setting workouts manually MUST mark the session as overridden so program apply without force MUST NOT replace them.

#### Scenario: Attach copy to session
- **WHEN** the coach PATCHes a booked session with a student copy for that student
- **THEN** subsequent GET returns that `studentPlanId`, a one-element `workouts` list, and plan summary

#### Scenario: Attach two copies
- **WHEN** the coach PATCHes `workoutPlanIds` with two student copies of that student
- **THEN** GET returns both in order and `studentPlanId` equals the first

#### Scenario: Wrong student's copy rejected
- **WHEN** the coach attaches a copy assigned to a different student
- **THEN** the system rejects the request

#### Scenario: Detach
- **WHEN** the coach PATCHes `studentPlanId` null or `workoutPlanIds` empty
- **THEN** the session has no linked plans and lifecycle remains available

#### Scenario: Student cannot attach
- **WHEN** the student PATCHes `studentPlanId` or `workoutPlanIds`
- **THEN** the system rejects the request

## ADDED Requirements

### Requirement: Session stores a prescription snapshot for attached workouts
The system SHALL persist set prescription snapshots for each session workout item (exercise, order, reps, weightKg, durationSeconds) when workouts are attached by program apply or by coach PATCH. GET session MUST return snapshot sets as the workout content for that date. Completing the session without explicit logs MUST copy the snapshot, not the live student copy, into actual logs when logs exist in the product.

#### Scenario: Snapshot differs from later copy edit
- **WHEN** a Monday session was snapshotted at 80 kg and the coach later sets the copy start to 90 kg without force-applying that session
- **THEN** GET of that Monday session still shows 80 kg

#### Scenario: Complete uses snapshot
- **WHEN** the coach completes a booked session with no log payload and snapshots exist
- **THEN** stored actual logs match the snapshot sets
