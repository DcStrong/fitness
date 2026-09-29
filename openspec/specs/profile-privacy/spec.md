# profile-privacy Specification

## Purpose
Define own-profile management, safe privacy defaults, and privacy-safe public projections.

## Requirements

### Requirement: User manages an own profile
The system SHALL allow an authenticated user with `profiles:update_own` to read and update only their own validated profile fields, including optional phone, Telegram username, and preferred contact channels. Missing legacy profiles SHALL remain valid and be created on first successful update.

#### Scenario: User saves contact preferences
- **WHEN** a user submits a valid international phone, Telegram username, and preferred channels whose values are present
- **THEN** the system creates or updates only that user's profile and returns the normalized owner projection

#### Scenario: Preferred channel has no value
- **WHEN** a user selects phone or Telegram as preferred without providing the corresponding valid value
- **THEN** the system rejects the update without persisting a partial profile

#### Scenario: Invalid profile is rejected
- **WHEN** a user submits an invalid HTTPS URL, contact format, over-limit text, or unsupported training/contact mode
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
Any social public profile response MUST exclude email, phone, Telegram username, preferred contact channels, password metadata, roles, permissions, student identifiers, relationships, Sessions, BookingRequests, plans, internal tags, and finance data.

#### Scenario: Public trainer is read
- **WHEN** an authenticated user opens a discoverable trainer profile
- **THEN** the response contains only allowlisted public profile, portfolio, rating, review, and viewer-scoped relationship fields

#### Scenario: Public DTO is serialized after contacts are configured
- **WHEN** a trainer with configured phone and Telegram is returned through discovery or public-profile API
- **THEN** none of those contact values or preferences are present in the response

### Requirement: Email is the private contact fallback
The owner and linked-only contact projections SHALL treat the authenticated user's account email as an available fallback channel without copying it into public profile fields or requiring duplicate profile storage.

#### Scenario: No optional contacts configured
- **WHEN** a linked participant has neither phone nor Telegram configured
- **THEN** the linked contact projection returns email as the available fallback

### Requirement: Reviewer attribution follows student privacy
Public review responses SHALL show a student's display name/avatar only when that student enabled reviewer-name visibility; otherwise the author SHALL be anonymous and MUST NOT expose a stable student identifier.

#### Scenario: Private reviewer is anonymized
- **WHEN** a student with reviewer-name visibility disabled has a visible review
- **THEN** public readers see the author as «Ученик» without email, user ID, or avatar
