## ADDED Requirements

### Requirement: Trainer can manage own exercises and read catalog exercises
The system SHALL allow a user with `exercises:manage_own` to create, update, delete, and list exercises they own. An exercise MUST have a non-empty `name` and a `kind` of `weight_reps`, `bodyweight_reps`, or `duration`. Catalog exercises (`ownerCoachId` null) MUST be readable by users with `exercises:read_own` or `exercises:manage_own` and MUST NOT be mutated via the API.

#### Scenario: Create own exercise
- **WHEN** a trainer creates an exercise with a name and kind
- **THEN** the exercise is stored as owned by that trainer and appears in their exercise list

#### Scenario: Catalog exercise is listed
- **WHEN** a trainer lists exercises
- **THEN** catalog seed exercises are included alongside own exercises and are distinguishable as catalog

#### Scenario: Mutate catalog rejected
- **WHEN** a user attempts to update or delete a catalog exercise
- **THEN** the system rejects the request

#### Scenario: Delete referenced own exercise rejected
- **WHEN** a trainer deletes an own exercise that is referenced by a plan exercise
- **THEN** the system rejects the request

#### Scenario: Non-owner cannot update
- **WHEN** another user attempts to update a trainer's exercise
- **THEN** the system rejects the request
