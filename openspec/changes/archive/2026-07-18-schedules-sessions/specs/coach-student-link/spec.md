## ADDED Requirements

### Requirement: Booking requires an active coach–student link
The system SHALL require an active coach–student relationship before a student may book that coach's slot or a coach may book a session for that student.

#### Scenario: Link present allows booking path
- **WHEN** an active link exists between coach and student
- **THEN** booking APIs for that pair are allowed (subject to other validation)

#### Scenario: Missing link blocks booking
- **WHEN** no active link exists
- **THEN** booking requests for that pair are rejected
