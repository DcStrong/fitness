## ADDED Requirements

### Requirement: Trainer can sign in on the web console
The web app SHALL allow a user to authenticate with email and password against the existing auth API and establish a session for subsequent API calls.

#### Scenario: Successful trainer login
- **WHEN** a trainer submits valid credentials on the login page
- **THEN** the app stores session credentials and navigates to the authenticated console area

#### Scenario: Invalid credentials rejected
- **WHEN** login fails
- **THEN** the user remains on login and sees an error message (Russian)

### Requirement: Only trainers may use the console
After authentication the web app SHALL load the current user profile and allow console access only if the user has the trainer role (or equivalent trainer capability). Non-trainers MUST be blocked from console routes.

#### Scenario: Student is denied console
- **WHEN** a student successfully authenticates
- **THEN** the app does not expose coach console navigation and shows that the console is for trainers only (or logs them out)

#### Scenario: Unauthenticated redirected to login
- **WHEN** a guest opens a protected console route
- **THEN** the app redirects to the login page

### Requirement: Trainer can log out
The web app SHALL clear the local session and return to login on logout (and SHOULD revoke refresh via existing logout API when a refresh token is available).

#### Scenario: Logout clears session
- **WHEN** an authenticated trainer logs out
- **THEN** subsequent visits to protected routes require login again
