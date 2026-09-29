## ADDED Requirements

### Requirement: Trainer can filter own templates by tag
The system SHALL allow a user with `plans:read_own` to list own `kind=template` plans filtered by a tag they created. Plans that do not include the tag MUST be omitted.

#### Scenario: Filter own templates by tag
- **WHEN** a trainer lists own plans with a tag they own
- **THEN** only templates that include that tag are returned

### Requirement: Trainer can assign multiple templates to one student in one request
The system SHALL allow the template owner with `plans:create` to assign many own `kind=template` plans to one linked student in a single request. For each plan the system MUST reuse or create a `kind=student_copy` as in single-template assign. The request MUST be transactional: if any plan is foreign or the student is unlinked, no copies are written. An empty `planIds` list MUST be rejected.

#### Scenario: Assign two templates to one student
- **WHEN** a trainer assigns two own templates to a linked student
- **THEN** a `kind=student_copy` exists for each template for that student and the templates are unchanged

#### Scenario: Batch with unlinked student rejected
- **WHEN** a trainer includes a user who is not a linked student
- **THEN** the system rejects the request and creates no copies
