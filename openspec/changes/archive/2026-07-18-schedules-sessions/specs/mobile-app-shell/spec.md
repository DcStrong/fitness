## ADDED Requirements

### Requirement: Router exposes schedule and session routes
The Flutter app shell SHALL register authenticated routes for trainer schedule management, student booking, and sessions list (e.g. `/schedule`, `/sessions`, `/sessions/book`).

#### Scenario: Authenticated user opens sessions
- **WHEN** a logged-in user navigates to the sessions route
- **THEN** the sessions screen is shown

#### Scenario: Unauthenticated redirected
- **WHEN** a logged-out user hits schedule/sessions routes
- **THEN** the router redirects to login
