## ADDED Requirements

### Requirement: Invitation and relationship permissions exist in catalog
The system SHALL include permission codes for invitation and relationship flows, for example `invitations:create`, `invitations:read_own`, `invitations:revoke`, `invitations:accept`, and `relationships:read_own`, and assign them to the appropriate seeded roles (`trainer` and/or `student`).

#### Scenario: Trainer role receives create/list/revoke
- **WHEN** seed runs on a fresh database
- **THEN** role `trainer` includes permissions to create, read own, and revoke invitations plus read own relationships

#### Scenario: Student role receives accept
- **WHEN** seed runs on a fresh database
- **THEN** role `student` includes permission to accept invitations and read own relationships

#### Scenario: Authorization still permission-based
- **WHEN** invitation endpoints are protected
- **THEN** guards check permission codes, not role name string equality
