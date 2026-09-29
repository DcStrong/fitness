## ADDED Requirements

### Requirement: Trainer can list assigned student copies separately from templates
The system SHALL NOT include `kind=student_copy` rows in the default trainer own-templates list. When assigned scope with a linked `studentId` is requested, the system SHALL return that trainer's copies for the student.

#### Scenario: Default list omits copies
- **WHEN** a trainer lists own plans with default template scope
- **THEN** `kind=student_copy` plans are not returned

#### Scenario: Assigned scope for student
- **WHEN** a trainer lists assigned plans for a linked student
- **THEN** that student's copies are returned
