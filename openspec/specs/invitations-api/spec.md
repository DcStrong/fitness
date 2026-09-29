# invitations-api Specification

## Purpose
TBD - created by archiving change invitations-qr. Update Purpose after archive.
## Requirements
### Requirement: Trainer can create an invitation
The system SHALL allow an authenticated user with permission `invitations:create` to create an invitation owned by themselves as coach. Each invitation MUST have a unique opaque token (or token hash), status `pending`, and an expiry timestamp.

#### Scenario: Successful create
- **WHEN** a trainer calls create-invitation with a valid authenticated session
- **THEN** the system returns invitation id, token (or invite URL material), status `pending`, expiresAt, and coach id

#### Scenario: Non-trainer denied
- **WHEN** a user without `invitations:create` calls create-invitation
- **THEN** the system rejects the request as forbidden

### Requirement: Trainer can list own invitations
The system SHALL allow a user with `invitations:read_own` to list invitations they created as coach.

#### Scenario: List returns owned invitations
- **WHEN** a trainer lists invitations
- **THEN** only invitations where coachId equals the caller are returned

### Requirement: Trainer can revoke a pending invitation
The system SHALL allow a coach with `invitations:revoke` to revoke their own pending invitation, transitioning status to `revoked`.

#### Scenario: Revoke pending
- **WHEN** the owning trainer revokes a pending invitation
- **THEN** its status becomes `revoked` and it MUST NOT be acceptable afterwards

#### Scenario: Revoke foreign invitation denied
- **WHEN** a trainer attempts to revoke an invitation owned by another coach
- **THEN** the system rejects the request

### Requirement: Authenticated student can accept a valid invitation
The system SHALL allow a user with `invitations:accept` to accept a pending, non-expired, non-revoked invitation by token. On success the invitation status MUST become `accepted` and `acceptedByUserId` MUST be set to the acceptor.

#### Scenario: Accept pending invitation
- **WHEN** a student accepts a valid pending invitation token
- **THEN** the invitation becomes `accepted` and a coach–student link is created (see coach-student-link)

#### Scenario: Accept expired invitation rejected
- **WHEN** a student accepts an invitation past expiresAt
- **THEN** the system rejects the request and does not create a link

#### Scenario: Accept revoked or already accepted rejected
- **WHEN** a student accepts a revoked or already accepted invitation
- **THEN** the system rejects the request

#### Scenario: Coach cannot accept own invitation
- **WHEN** the coach who created the invitation attempts to accept it
- **THEN** the system rejects the request

### Requirement: Invitation token is opaque and verified server-side
The invitation token exposed in QR/deep link MUST be opaque to clients. The server MUST verify token validity (existence, status, expiry) on accept; clients MUST NOT rely on unsigned client-side payload alone.

#### Scenario: Unknown token rejected
- **WHEN** accept is called with an unknown token
- **THEN** the system rejects the request without leaking whether the token ever existed beyond a generic failure

