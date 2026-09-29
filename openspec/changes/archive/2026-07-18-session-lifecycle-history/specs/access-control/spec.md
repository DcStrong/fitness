## ADDED Requirements

### Requirement: Session lifecycle and history permissions exist in catalog
The system SHALL include permission codes `sessions:complete`, `sessions:cancel`, `sessions:mark_no_show`, and `sessions:read_history`, assigned to seeded roles: trainer gets all four; student gets `sessions:cancel` and `sessions:read_history`.

#### Scenario: Trainer seed includes lifecycle permissions
- **WHEN** seed runs
- **THEN** role `trainer` includes complete, cancel, mark_no_show, and read_history

#### Scenario: Student seed includes cancel and read_history
- **WHEN** seed runs
- **THEN** role `student` includes cancel and read_history but not complete or mark_no_show

#### Scenario: Guards remain permission-based
- **WHEN** lifecycle endpoints are protected
- **THEN** authorization checks permission codes, not role name equality
