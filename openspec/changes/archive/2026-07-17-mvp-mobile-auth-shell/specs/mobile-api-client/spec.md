## ADDED Requirements

### Requirement: HTTP client uses configurable base URL
The app SHALL use a Dio-based API client with a configurable base URL suitable for device/emulator (e.g. `http://10.0.2.2:3000` on Android emulator, `http://localhost:3000` on iOS simulator).

#### Scenario: Request hits Nest health
- **WHEN** the client performs a health or auth request against the configured base URL with API running
- **THEN** the request reaches the Nest server (not a hard-coded wrong host)

### Requirement: Tokens stored securely
Access and refresh tokens SHALL be stored using `flutter_secure_storage` (not plaintext SharedPreferences).

#### Scenario: Tokens persist across restart
- **WHEN** the user logs in successfully and restarts the app
- **THEN** tokens are still available from secure storage for session restore

### Requirement: Access token attached to authenticated calls
Authenticated API calls SHALL include `Authorization: Bearer <accessToken>`.

#### Scenario: Me sends bearer header
- **WHEN** the app calls `GET /users/me` while logged in
- **THEN** the request includes the Bearer access token

### Requirement: Refresh on unauthorized
When an authenticated request fails with 401 (excluding auth endpoints), the client SHALL attempt `POST /auth/refresh` once with the stored refresh token, update stored tokens on success, and retry the original request; on refresh failure it SHALL clear session.

#### Scenario: Access expired but refresh valid
- **WHEN** a 401 occurs and refresh succeeds
- **THEN** new tokens are stored and the original request is retried successfully

#### Scenario: Refresh invalid
- **WHEN** refresh fails
- **THEN** tokens are cleared and the session becomes unauthenticated
