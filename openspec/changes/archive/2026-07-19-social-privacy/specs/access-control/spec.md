## ADDED Requirements

### Requirement: Social and privacy permissions exist in catalog
The system SHALL include permission codes `profiles:read_public`, `profiles:update_own`, `profiles:manage_privacy`, `portfolio:manage_own`, `reviews:read`, `reviews:create_own`, and `reviews:update_own`.

#### Scenario: Trainer permissions are seeded
- **WHEN** permission seed runs
- **THEN** trainer receives public profile read, own profile/privacy/portfolio management, and review read permissions

#### Scenario: Student permissions are seeded
- **WHEN** permission seed runs
- **THEN** student receives public profile read, own profile/privacy management, and own review read/create/update permissions without portfolio management

### Requirement: Social authorization combines permission and resource policy
Every social write SHALL require the relevant permission plus owner, Session participant/status, or visibility checks. Role-name equality alone MUST NOT authorize a resource operation.

#### Scenario: Permission without ownership is insufficient
- **WHEN** a user with an own-resource permission targets another user's profile, portfolio, or review
- **THEN** the system rejects the operation
