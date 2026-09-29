## ADDED Requirements

### Requirement: Tag and plan permissions exist in catalog
The system SHALL include permission codes `tags:create`, `tags:read_own`, `tags:delete_own`, `tags:assign`, `plans:create`, `plans:read_own`, `plans:read_visible`, `plans:update_own`, and `plans:delete_own`, assigned to seeded roles: trainer gets tag manage + plan manage; student gets `tags:read_own` and `plans:read_visible`.

#### Scenario: Trainer seed includes tag and plan manage
- **WHEN** seed runs
- **THEN** role `trainer` includes create/read/delete/assign tags and create/read/update/delete own plans

#### Scenario: Student seed includes read tags and visible plans
- **WHEN** seed runs
- **THEN** role `student` includes `tags:read_own` and `plans:read_visible` but not plan create/update/delete

#### Scenario: Guards remain permission-based
- **WHEN** tag or plan endpoints are protected
- **THEN** authorization checks permission codes, not role name equality
