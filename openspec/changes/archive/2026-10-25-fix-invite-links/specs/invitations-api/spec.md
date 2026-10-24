## ADDED Requirements

### Requirement: Invite URL is built from configured web base
The system SHALL return `inviteUrl` as `<INVITE_HTTPS_BASE>/i/<token>` (trailing slash and a pre-existing `/i` suffix in the base tolerated) and `deepLink` as `<INVITE_SCHEME_BASE>/<token>`. When `INVITE_HTTPS_BASE` is unset the base MUST default to `http://localhost:8080`; the system MUST NOT default to a non-existent domain.

#### Scenario: Configured base
- **WHEN** `INVITE_HTTPS_BASE=https://app.example.com` and a trainer creates an invitation
- **THEN** `inviteUrl` equals `https://app.example.com/i/<token>`

#### Scenario: Default base
- **WHEN** `INVITE_HTTPS_BASE` is not set
- **THEN** `inviteUrl` equals `http://localhost:8080/i/<token>`
