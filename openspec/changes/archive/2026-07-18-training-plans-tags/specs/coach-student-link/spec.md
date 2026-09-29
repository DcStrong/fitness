## ADDED Requirements

### Requirement: Tag assignment requires an active coach–student link
The system SHALL require an active coach–student relationship before a coach may assign one of their tags to a student user.

#### Scenario: Link present allows tag assign
- **WHEN** an active link exists between coach and student
- **THEN** tag assignment APIs for that pair are allowed (subject to ownership of the tag)

#### Scenario: Missing link blocks tag assign
- **WHEN** no active link exists
- **THEN** tag assignment requests for that pair are rejected
