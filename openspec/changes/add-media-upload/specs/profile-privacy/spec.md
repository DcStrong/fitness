## ADDED Requirements

### Requirement: Profile image URLs
`avatarUrl` SHALL be either a URL of the system's own storage (as returned by `POST /media/images`) or an external HTTPS URL; any other URL (for example external `http://`) MUST be rejected with 400.

#### Scenario: Uploaded avatar
- **WHEN** a user saves `avatarUrl` returned by the upload endpoint
- **THEN** the profile is updated

#### Scenario: Foreign http URL
- **WHEN** a user saves `avatarUrl` with an external `http://` address
- **THEN** the system responds 400
