## MODIFIED Requirements

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

### Requirement: Public profile projection excludes private data
Any social public profile response MUST exclude email, phone, Telegram username, preferred contact channels, password metadata, roles, permissions, student identifiers, relationships, Sessions, BookingRequests, plans, internal tags, and finance data.

#### Scenario: Public trainer is read
- **WHEN** an authenticated user opens a discoverable trainer profile
- **THEN** the response contains only allowlisted public profile, portfolio, rating, review, and viewer-scoped relationship fields

#### Scenario: Public DTO is serialized after contacts are configured
- **WHEN** a trainer with configured phone and Telegram is returned through discovery or public-profile API
- **THEN** none of those contact values or preferences are present in the response

## ADDED Requirements

### Requirement: Email is the private contact fallback
The owner and linked-only contact projections SHALL treat the authenticated user's account email as an available fallback channel without copying it into public profile fields or requiring duplicate profile storage.

#### Scenario: No optional contacts configured
- **WHEN** a linked participant has neither phone nor Telegram configured
- **THEN** the linked contact projection returns email as the available fallback
