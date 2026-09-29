## ADDED Requirements

### Requirement: Router exposes authenticated finance routes
The Flutter app shell SHALL register authenticated routes for trainer finance summary/settings/ledger and Session charge details. Existing auth redirects MUST protect these routes.

#### Scenario: Trainer opens wallet
- **WHEN** an authenticated trainer navigates to the finance route
- **THEN** the trainer finance screen is shown

#### Scenario: Unauthenticated finance route access
- **WHEN** a logged-out user opens a finance route
- **THEN** the app redirects to login
