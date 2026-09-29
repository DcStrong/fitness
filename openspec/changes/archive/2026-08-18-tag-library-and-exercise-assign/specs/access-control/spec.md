## ADDED Requirements

### Requirement: Exercise visibility permission exists in catalog
The system SHALL include permission code `exercises:read_visible` and assign it to the seeded `student` role. The seeded `trainer` role MUST retain `exercises:manage_own` and `exercises:read_own` and MUST NOT require `exercises:read_visible` to manage tags or assignments.

#### Scenario: Student seed includes visible exercises
- **WHEN** seed runs
- **THEN** role `student` includes `exercises:read_visible` in addition to `exercises:read_own`

#### Scenario: Visible exercises guard is permission-based
- **WHEN** the visible-exercises endpoint is protected
- **THEN** authorization checks `exercises:read_visible`, not role name equality
