## ADDED Requirements

### Requirement: User manages an own profile
The system SHALL allow an authenticated user with `profiles:update_own` to read and update only their own validated profile fields. Missing legacy profiles SHALL remain valid and be created on first successful update.

#### Scenario: Student creates own profile
- **WHEN** a student updates a valid display name and avatar URL
- **THEN** the system creates or updates only that student's profile

#### Scenario: Invalid profile is rejected
- **WHEN** a user submits an invalid HTTPS URL, over-limit text, or unsupported training mode
- **THEN** the system rejects the update without persisting a partial profile

### Requirement: Privacy settings use safe defaults
New and legacy profiles SHALL default to `isDiscoverable=false`. A student profile MUST NOT enter trainer discovery regardless of submitted privacy values.

#### Scenario: New trainer is hidden
- **WHEN** a trainer creates a profile without publishing it
- **THEN** the trainer is absent from discovery and direct public profile reads

#### Scenario: Student cannot become discoverable trainer
- **WHEN** a student attempts to enable trainer discoverability
- **THEN** the system rejects or ignores that unsupported setting and does not publish the student

### Requirement: User manages only own privacy settings
The system SHALL allow a user with `profiles:manage_privacy` to update their own supported visibility settings and MUST reject updates to another user's settings.

#### Scenario: Trainer publishes complete profile
- **WHEN** a trainer with a valid display name enables discoverability
- **THEN** the profile becomes eligible for trainer discovery immediately

#### Scenario: Foreign privacy update is denied
- **WHEN** a user attempts to change another user's privacy settings
- **THEN** the system rejects the request

### Requirement: Public profile projection excludes private data
Any social public profile response MUST exclude email, password metadata, roles, permissions, student identifiers, relationships, Sessions, plans, internal tags, and finance data.

#### Scenario: Public trainer is read
- **WHEN** an authenticated user opens a discoverable trainer profile
- **THEN** the response contains only allowlisted public profile, portfolio, rating, review, and viewer-scoped relationship fields

### Requirement: Reviewer attribution follows student privacy
Public review responses SHALL show a student's display name/avatar only when that student enabled reviewer-name visibility; otherwise the author SHALL be anonymous and MUST NOT expose a stable student identifier.

#### Scenario: Private reviewer is anonymized
- **WHEN** a student with reviewer-name visibility disabled has a visible review
- **THEN** public readers see the author as «Ученик» without email, user ID, or avatar
