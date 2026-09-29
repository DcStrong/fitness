## ADDED Requirements

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
