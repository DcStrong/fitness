# workout-assignments-api Specification

## Purpose
HTTP API to assign one or many workout templates to linked students as independent `kind=student_copy` plans, list those copies, and customize a copy without mutating the parent template.

## Requirements

### Requirement: Trainer can assign a template to linked students as independent copies
The system SHALL allow the template owner with `plans:create` to assign a `kind=template` plan to one or more linked students by `studentIds` and/or own `tagIds`. For each resolved student the system MUST reuse an existing `kind=student_copy` for that `(parentTemplateId, studentId)` or create a new copy with cloned title, goal, notes, and exercise/set structure. The source template MUST NOT be mutated. Assigning to an unlinked user MUST be rejected. An empty resolved student set MUST be rejected.

#### Scenario: Assign to one student
- **WHEN** a trainer assigns a template to a linked student
- **THEN** a `kind=student_copy` exists for that student with the same exercise structure and the template is unchanged

#### Scenario: Re-assign is idempotent
- **WHEN** a trainer assigns the same template to the same student again
- **THEN** no second copy is created and the existing copy id is returned

#### Scenario: Assign via tag
- **WHEN** a trainer assigns a template with a tag that is on two linked students
- **THEN** each of those students receives a copy (reused if already present)

#### Scenario: Unlinked student rejected
- **WHEN** a trainer includes a user who is not a linked student
- **THEN** the system rejects the request and creates no copies

### Requirement: Trainer can edit a student copy without changing the template
The system SHALL allow the owning coach to update a `kind=student_copy` plan (title, goal, notes, tags, exercises) without modifying `parentTemplateId` or other students' copies. Updating the parent template MUST NOT rewrite existing copies. Students MAY read their assigned copies and MUST NOT mutate them.

#### Scenario: Customize one student
- **WHEN** the coach changes sets on a student copy
- **THEN** the parent template and other copies keep their previous sets

#### Scenario: Student cannot patch copy
- **WHEN** the assigned student PATCHes the copy
- **THEN** the system rejects the request

### Requirement: Users can list assigned copies
The system SHALL let a trainer with `plans:read_own` list `kind=student_copy` plans for a linked `studentId`, and let a student with `plans:read_visible` or `plans:read_own` list copies assigned to themselves.

#### Scenario: Trainer lists a student's copies
- **WHEN** a trainer lists assigned plans for a linked student
- **THEN** only that student's copies owned by the trainer are returned

#### Scenario: Student lists own copies
- **WHEN** a student lists assigned plans
- **THEN** copies where `assignedStudentId` is that student are returned

### Requirement: Trainer can assign multiple templates to one student in one request
The system SHALL allow the template owner with `plans:create` to assign many own `kind=template` plans to one linked student in a single request. For each plan the system MUST reuse or create a `kind=student_copy` as in single-template assign. The request MUST be transactional: if any plan is foreign or the student is unlinked, no copies are written. An empty `planIds` list MUST be rejected.

#### Scenario: Assign two templates to one student
- **WHEN** a trainer assigns two own templates to a linked student
- **THEN** a `kind=student_copy` exists for each template for that student and the templates are unchanged

#### Scenario: Batch with unlinked student rejected
- **WHEN** a trainer includes a user who is not a linked student
- **THEN** the system rejects the request and creates no copies

### Requirement: Program assign reuses existing student copies
When a workout program upsert resolves templates for the series student, the system SHALL reuse the existing `kind=student_copy` for each `(parentTemplateId, studentId)` pair instead of creating a second copy. Reuse MUST keep coach customizations already stored on that copy except start weights explicitly written by progression rolling or a loads PATCH.

#### Scenario: Program uses existing copy
- **WHEN** the student already has a copy of «Силовая» and the coach adds «Силовая» to Monday on the program
- **THEN** Monday items reference that same copy id

#### Scenario: Second copy is not created
- **WHEN** the coach saves the same program again
- **THEN** no additional `student_copy` rows exist for that template and student
