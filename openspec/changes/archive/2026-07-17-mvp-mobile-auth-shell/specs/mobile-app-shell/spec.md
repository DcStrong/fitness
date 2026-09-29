## ADDED Requirements

### Requirement: App boots with router and auth gate
The Flutter app SHALL start with `MaterialApp.router` using `go_router` and SHALL redirect based on authentication session state.

#### Scenario: Cold start without tokens
- **WHEN** the app starts and no access token is stored
- **THEN** the user is shown the login route (or equivalent unauthenticated entry)

#### Scenario: Cold start with valid session
- **WHEN** the app starts with a stored access token and `/users/me` succeeds
- **THEN** the user is taken to the home route without seeing login

### Requirement: Home shows signed-in profile stub
The home screen SHALL display the authenticated user's email and at least one of roles or permissions, plus a logout action.

#### Scenario: Home after login
- **WHEN** the user reaches home while authenticated
- **THEN** the UI shows the user email from `/users/me` (or last auth response) and a logout control
