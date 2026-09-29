## ADDED Requirements

### Requirement: Schedule and session permissions exist in catalog
The system SHALL include permission codes such as `schedules:create`, `schedules:read_own`, `schedules:delete_own`, `schedules:read_linked`, `sessions:book_self`, `sessions:book_for_student`, `sessions:read_own`, and assign them to seeded `trainer` / `student` roles appropriately.

#### Scenario: Trainer seed permissions
- **WHEN** seed runs
- **THEN** trainer includes schedule manage + book_for_student + sessions read_own

#### Scenario: Student seed permissions
- **WHEN** seed runs
- **THEN** student includes schedules read_linked + sessions book_self + sessions read_own

#### Scenario: Guards remain permission-based
- **WHEN** schedule/session endpoints are protected
- **THEN** authorization checks permission codes, not role name equality
