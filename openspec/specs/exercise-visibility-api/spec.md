# exercise-visibility-api Specification

## Purpose
HTTP API to assign exercises to linked students without cloning rows, and to include those assignments in the student's visible exercise list.

## Requirements

### Requirement: Trainer can assign exercises to linked students
The system SHALL allow a user with `exercises:manage_own` to assign own or catalog exercises to linked students by `studentIds` and/or own `tagIds`. Assignment MUST NOT clone the exercise row. Re-assigning the same exercise to the same student MUST be idempotent. Assigning to an unlinked user MUST be rejected. An empty resolved student set or empty exercise set MUST be rejected. The trainer MAY unassign that pairing.

#### Scenario: Assign exercises to one student
- **WHEN** a trainer assigns two catalog or own exercises to a linked student
- **THEN** both exercises are associated with that student and the exercise definitions are unchanged

#### Scenario: Assign via tag
- **WHEN** a trainer assigns exercises with a tag that is on two linked students
- **THEN** each of those students receives the exercise associations (reused if already present)

#### Scenario: Unlinked student rejected
- **WHEN** a trainer includes a user who is not a linked student
- **THEN** the system rejects the request and creates no associations

### Requirement: Visible list includes explicit assignments
The system SHALL include explicitly assigned exercises in the student's `GET /exercises/visible` result even when no tag overlaps, provided the assigning coach is linked.

#### Scenario: Assigned without shared tag
- **WHEN** a linked student has an explicit exercise assignment and no shared tag
- **THEN** that exercise still appears in the visible list
