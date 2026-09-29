## ADDED Requirements

### Requirement: Program assign reuses existing student copies
When a workout program upsert resolves templates for the series student, the system SHALL reuse the existing `kind=student_copy` for each `(parentTemplateId, studentId)` pair instead of creating a second copy. Reuse MUST keep coach customizations already stored on that copy except start weights explicitly written by progression rolling or a loads PATCH.

#### Scenario: Program uses existing copy
- **WHEN** the student already has a copy of «Силовая» and the coach adds «Силовая» to Monday on the program
- **THEN** Monday items reference that same copy id

#### Scenario: Second copy is not created
- **WHEN** the coach saves the same program again
- **THEN** no additional `student_copy` rows exist for that template and student
