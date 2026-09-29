# mobile-auth Specification

## Purpose
TBD - created by archiving change mvp-mobile-auth-shell. Update Purpose after archive.
## Requirements
### Requirement: User can register from mobile
The mobile app SHALL allow registration with email, password (min 8 chars), and role `trainer` or `student` via `POST /auth/register`, then persist tokens and enter the authenticated shell.

#### Scenario: Successful register as trainer
- **WHEN** the user submits valid email, password, and role `trainer`
- **THEN** the app stores access and refresh tokens securely and navigates to home

#### Scenario: Duplicate email surfaces error
- **WHEN** registration fails because the email already exists
- **THEN** the app shows an error and does not navigate to home

### Requirement: User can log in from mobile
The mobile app SHALL authenticate via `POST /auth/login` with email and password, persist tokens, and enter the authenticated shell.

#### Scenario: Successful login
- **WHEN** the user submits correct credentials
- **THEN** tokens are stored and the app navigates to home

#### Scenario: Invalid credentials
- **WHEN** login fails with unauthorized/invalid credentials
- **THEN** the app shows an error and remains on the login screen

### Requirement: Session restore calls me
On app start, if an access token exists, the app SHALL call `GET /users/me` to restore the session profile.

#### Scenario: Me succeeds
- **WHEN** a stored access token is accepted by `/users/me`
- **THEN** the app becomes authenticated with that profile

#### Scenario: Me fails and refresh fails
- **WHEN** `/users/me` fails and token refresh cannot recover the session
- **THEN** the app clears stored tokens and shows the login screen

### Requirement: User can log out
The mobile app SHALL revoke the refresh token via `POST /auth/logout` when possible, clear secure storage, and return to login.

#### Scenario: Logout from home
- **WHEN** the authenticated user taps logout
- **THEN** local tokens are cleared and the login route is shown

### Requirement: Login and Register use brand hero décor without contract changes
Login and Register SHALL present a brand hero region with the bundled Fitness Yoda illustration asset when available, soft mint decorative shapes, and a hero-to-form proportion consistent with `app/design/mapping-fitness-yoda.md` (~40–42% hero when the keyboard is closed). Email, password, role selection, validators, submission events, loading, errors, and navigation MUST remain unchanged.

#### Scenario: Successful login still works
- **WHEN** the user submits valid credentials on the polished Login screen
- **THEN** the existing authentication submission flow runs unchanged and navigates as before

#### Scenario: Register role unchanged
- **WHEN** the user selects trainer or student on polished Register
- **THEN** the form still submits the same role value expected by the authentication contract

#### Scenario: Compact height remains scrollable
- **WHEN** Login or Register is shown on a short viewport or with the keyboard open
- **THEN** the form remains scrollable without overflow and CTA/fields stay reachable
