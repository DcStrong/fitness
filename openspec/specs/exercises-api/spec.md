# exercises-api Specification

## Purpose
HTTP API for the trainer exercise library, gym-only catalog seed, trainer-owned tags on exercises, and a student's visible exercise list.

## Requirements

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

### Requirement: Catalog seed is gym-only strength work
The system SHALL seed catalog exercises and `kind=catalog_seed` templates with gym strength movements only (barbell/dumbbell/machine/bodyweight gym work such as bench press, squat, pull-ups, rows, presses). Catalog MUST NOT include running, cycling, elliptical, or other outdoor/cardio-machine work. Re-seed MUST be idempotent: retired catalog names (e.g. bicycle) SHALL be renamed or left unused rather than breaking plans that already reference their ids.

#### Scenario: Catalog list has no cycling or running
- **WHEN** a trainer lists catalog exercises after seed
- **THEN** names do not include велосипед, бег, or equivalent cardio-outside-gym movements

#### Scenario: Hypertrophy/fat-loss catalog templates stay gym
- **WHEN** a trainer opens a catalog fat-loss template
- **THEN** its exercises are gym movements (higher-rep strength), not bike/run intervals

### Requirement: Trainer can attach own tags to exercises
The system SHALL allow a user with `exercises:manage_own` to set an exercise's tag set to tags they created, including catalog seed exercises, without mutating catalog name or kind. Foreign tags MUST be rejected. Own-exercise create and update MUST accept `tagIds`.

#### Scenario: Tag own exercise
- **WHEN** a trainer sets `tagIds` they own on an exercise they own
- **THEN** those tags are linked to the exercise

#### Scenario: Tag catalog exercise without mutating catalog
- **WHEN** a trainer sets own tags on a catalog seed exercise
- **THEN** the tags are linked for that trainer and the catalog name and kind are unchanged

#### Scenario: Foreign tag rejected
- **WHEN** a trainer includes a tagId they did not create
- **THEN** the system rejects the request

### Requirement: Student can list visible exercises via shared tags
The system SHALL allow a user with `exercises:read_visible` to list exercises that are **visible**: the exercise is tagged with a tag created by a linked coach, and that tag is assigned to the student. Exercises with no overlapping tag MUST NOT appear unless explicitly assigned (see exercise-visibility-api assign).

#### Scenario: Shared tag makes exercise visible
- **WHEN** a linked student shares at least one tag with a coach-tagged exercise
- **THEN** that exercise appears in the student's visible exercises list

#### Scenario: No shared tag hides unassigned exercise
- **WHEN** a linked student has no tag in common with an exercise and it is not explicitly assigned
- **THEN** that exercise does not appear in the visible list

#### Scenario: Unlinked coach exercise not visible
- **WHEN** a student is not linked to the tag's creator
- **THEN** the exercise is not visible even if tag names coincide
