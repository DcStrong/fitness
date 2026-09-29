## MODIFIED Requirements

### Requirement: Authorization decisions use permissions
The system SHALL authorize protected actions by checking permissions, not by comparing role name strings in business logic. Effective permissions MUST be resolved from TypeORM-backed role/permission relations.

#### Scenario: Permission grants access
- **WHEN** an authenticated user has permission `users:read_self` and calls an endpoint that requires that permission
- **THEN** the system allows the request

#### Scenario: Missing permission denies access
- **WHEN** an authenticated user lacks the required permission for an endpoint
- **THEN** the system rejects the request as forbidden

### Requirement: Roles are permission bundles
The system SHALL model roles as named sets of permissions that can be assigned to users. Seeded roles MUST include at least `trainer`, `student`, and `admin`.

#### Scenario: Seeded roles exist after migrate/seed
- **WHEN** database seed runs on a fresh environment
- **THEN** roles `trainer`, `student`, and `admin` exist with their configured permission sets

#### Scenario: Effective permissions are union of role permissions
- **WHEN** a user is assigned one or more roles
- **THEN** `/me` (or equivalent) returns the union of permissions from those roles without duplicates

### Requirement: Initial registration assigns a non-admin role bundle
The system SHALL allow registration to request either `trainer` or `student` as the initial role. The system MUST NOT allow self-registration into `admin`.

#### Scenario: Register as trainer
- **WHEN** a client registers requesting role `trainer`
- **THEN** the user receives the `trainer` permission bundle

#### Scenario: Register as student
- **WHEN** a client registers requesting role `student`
- **THEN** the user receives the `student` permission bundle

#### Scenario: Self-register as admin rejected
- **WHEN** a client attempts to register requesting role `admin`
- **THEN** the system rejects the request

### Requirement: Permission catalog is extensible
The system SHALL store permissions as stable string codes (for example `sessions:create`) so new permissions can be added later without changing the authorization mechanism.

#### Scenario: New permission can be seeded
- **WHEN** a new permission code is added to seed data and linked to a role
- **THEN** users with that role receive the new permission on subsequent authentication/profile reads without code changes to the guard mechanism
