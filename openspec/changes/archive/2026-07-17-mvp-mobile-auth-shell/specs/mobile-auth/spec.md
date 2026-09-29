## ADDED Requirements

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
