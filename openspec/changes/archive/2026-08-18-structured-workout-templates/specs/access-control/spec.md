## MODIFIED Requirements

### Requirement: Tag and plan permissions exist in catalog
The system SHALL include permission codes `tags:create`, `tags:read_own`, `tags:delete_own`, `tags:assign`, `plans:create`, `plans:read_own`, `plans:read_visible`, `plans:update_own`, `plans:delete_own`, `exercises:manage_own`, and `exercises:read_own`, assigned to seeded roles: trainer gets tag manage + plan manage + exercise manage; student gets `tags:read_own`, `plans:read_visible`, and `exercises:read_own`.

#### Scenario: Trainer seed includes tag and plan manage
- **WHEN** seed runs
- **THEN** role `trainer` includes create/read/delete/assign tags, create/read/update/delete own plans, and manage/read own exercises

#### Scenario: Student seed includes read tags and visible plans
- **WHEN** seed runs
- **THEN** role `student` includes `tags:read_own`, `plans:read_visible`, and `exercises:read_own` but not plan create/update/delete or exercise manage

#### Scenario: Guards remain permission-based for tags and plans
- **WHEN** tag, plan, or exercise endpoints are protected
- **THEN** authorization checks permission codes, not role name equality
