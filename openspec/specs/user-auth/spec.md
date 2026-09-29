# user-auth Specification

## Purpose
TBD - created by archiving change mvp-backend-auth-permissions. Update Purpose after archive.
## Requirements
### Requirement: User can register with email and password
The system SHALL allow a new user to register with a unique email and a password, without email verification or other secondary confirmation steps. The identity field MUST be email-only (not a free-form username). Persistence MUST use TypeORM entities/repositories (not Prisma).

#### Scenario: Successful registration
- **WHEN** a client submits a valid unique email and password to the registration endpoint
- **THEN** the system creates the user, assigns the requested initial role bundle (trainer or student), and returns auth tokens plus basic user profile

#### Scenario: Duplicate email rejected
- **WHEN** a client attempts to register with an email that already exists
- **THEN** the system rejects the request with a client error and does not create a second user

#### Scenario: Non-email identity rejected
- **WHEN** a client submits a registration identity that is not a valid email
- **THEN** the system rejects the request with a validation error

### Requirement: User can log in with email and password
The system SHALL authenticate existing users with email and password and issue JWT access and refresh tokens, loading credentials via TypeORM.

#### Scenario: Successful login
- **WHEN** a client submits correct email and password
- **THEN** the system returns access token, refresh token, and basic user profile including effective permissions

#### Scenario: Invalid credentials rejected
- **WHEN** a client submits an unknown email or incorrect password
- **THEN** the system rejects the request without revealing which field was wrong

### Requirement: User can refresh access token
The system SHALL issue a new access token when a valid refresh token is presented. Refresh token records MUST be stored and revoked via TypeORM.

#### Scenario: Successful refresh
- **WHEN** a client presents a valid refresh token
- **THEN** the system returns a new access token (and MAY rotate the refresh token)

#### Scenario: Invalid refresh rejected
- **WHEN** a client presents an expired or invalid refresh token
- **THEN** the system rejects the request with an unauthorized error

### Requirement: User can log out and revoke refresh token
The system SHALL provide a logout endpoint that invalidates the presented refresh token so it cannot be used again.

#### Scenario: Successful logout
- **WHEN** a client calls logout with a valid refresh token
- **THEN** the system revokes that refresh token and subsequent refresh attempts with it fail

#### Scenario: Logout with invalid refresh
- **WHEN** a client calls logout with an already revoked or unknown refresh token
- **THEN** the system responds idempotently with success or a client/unauthorized error without reactivating the token

### Requirement: Authenticated user can read own profile
The system SHALL expose a `/me` (or equivalent) endpoint that returns the current user profile and effective permissions for a valid access token. Profile data MUST be loaded via TypeORM.

#### Scenario: Me with valid token
- **WHEN** an authenticated client calls the profile endpoint with a valid access token
- **THEN** the system returns user id, email, assigned role names, and the list of effective permissions

#### Scenario: Me without token rejected
- **WHEN** a client calls the profile endpoint without a valid access token
- **THEN** the system rejects the request as unauthorized

