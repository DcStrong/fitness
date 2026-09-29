## ADDED Requirements

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
