## ADDED Requirements

### Requirement: Router exposes session history route
The Flutter app shell SHALL register an authenticated route for session history (e.g. `/sessions/:id/history`) gated by the existing auth redirect rules.

#### Scenario: Authenticated user opens history route
- **WHEN** a logged-in participant navigates to the session history route
- **THEN** the history screen is shown

#### Scenario: Unauthenticated redirected from history
- **WHEN** a logged-out user hits the session history route
- **THEN** the router redirects to login
