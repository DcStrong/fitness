## MODIFIED Requirements

### Requirement: Booking requires an active coach–student link
The system SHALL require an active coach–student relationship before a student may create/read a BookingRequest for that coach, before a coach may respond or assign alternate time, and before a coach may directly book a Session for that student. Relationship authorization MUST be revalidated at terminal request decisions.

#### Scenario: Link present allows request path
- **WHEN** an active link exists between coach and student
- **THEN** BookingRequest APIs for that pair are allowed subject to other validation

#### Scenario: Missing link blocks request creation
- **WHEN** no active link exists
- **THEN** BookingRequest creation for that pair is rejected

#### Scenario: Link missing at acceptance
- **WHEN** a relationship is no longer active when a coach attempts to accept a pending request
- **THEN** acceptance is rejected without creating a Session or charge

#### Scenario: Link present allows direct coach booking
- **WHEN** an active link exists between coach and student
- **THEN** coach book-for-student APIs for that pair remain allowed subject to other validation

## ADDED Requirements

### Requirement: Linked participants can read preferred contacts
The system SHALL expose a privacy-scoped contact projection only when caller and target participate in an active coach–student relationship. The projection SHALL contain the target's filled preferred phone/Telegram channels and email fallback, and MUST NOT expose unrelated profile or authorization data.

#### Scenario: Trainer reads linked student contacts
- **WHEN** a trainer preparing an alternate-time resolution requests contacts for their linked student
- **THEN** the response contains allowed preferred contacts and email fallback

#### Scenario: Student reads linked coach contacts
- **WHEN** a student requests contacts for their linked coach
- **THEN** the same linked-only policy is applied

#### Scenario: Unlinked contact read denied
- **WHEN** an authenticated user requests contacts for a user without an active relationship
- **THEN** the system rejects the request and returns no contact fields
