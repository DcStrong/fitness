## ADDED Requirements

### Requirement: Router exposes invitation routes
The Flutter app shell SHALL register routes for trainer invite UI and student accept/invite handling (for example `/invite` and `/invite/accept`), integrated with existing auth redirects so unauthenticated users cannot use trainer invite creation.

#### Scenario: Trainer can open invite route when authenticated
- **WHEN** an authenticated trainer navigates to the invite route
- **THEN** the invite screen is shown

#### Scenario: Unauthenticated blocked from trainer invite
- **WHEN** an unauthenticated user attempts the trainer invite route
- **THEN** the router redirects to login
