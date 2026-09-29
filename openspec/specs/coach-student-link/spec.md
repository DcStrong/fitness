# coach-student-link Specification

## Purpose
TBD - created by archiving change invitations-qr. Update Purpose after archive.
## Requirements
### Requirement: Accepting an invitation creates a coach–student relationship
When an invitation is successfully accepted, the system SHALL create a durable link between the invitation's coach and the accepting student user. Duplicate accepts for the same pair MUST be idempotent (no duplicate active links).

#### Scenario: First accept creates link
- **WHEN** a student successfully accepts a coach invitation
- **THEN** an active coach–student relationship exists for that pair

#### Scenario: Duplicate link is idempotent
- **WHEN** the same student accepts another invitation from the same coach while a link already exists
- **THEN** the system does not create a second active link and still reports success (or clearly reports already linked)

### Requirement: Accepting a booking request may create a coach–student relationship
When a coach successfully accepts a pending BookingRequest (requested slot or alternate time), the system SHALL ensure an active coach–student link exists for that pair, creating it in the same transaction when missing. Duplicate link creation MUST be idempotent. Rejecting or withdrawing a BookingRequest MUST NOT create a relationship.

#### Scenario: Accept without prior link creates relationship
- **WHEN** a coach accepts a pending BookingRequest for a student with no active link to that coach
- **THEN** an active coach–student relationship exists after acceptance and the Session/charge are created

#### Scenario: Reject without prior link leaves pair unlinked
- **WHEN** a coach rejects a pending BookingRequest for a student with no active link to that coach
- **THEN** no coach–student relationship is created

### Requirement: Users can read their coach–student links
The system SHALL expose a way for an authenticated user to read relationships they participate in (as coach and/or student), gated by permission `relationships:read_own`.

#### Scenario: Student sees linked coach
- **WHEN** a linked student requests their relationships
- **THEN** the response includes the coach identity needed for UI context (at least coach user id and email or display label)

#### Scenario: Coach sees linked students
- **WHEN** a linked coach requests their relationships
- **THEN** the response includes linked student identities

### Requirement: Booking creation and direct coach booking require an active coach–student link
The system SHALL require an active coach–student relationship before a student may create a BookingRequest for that coach and before a coach may directly book a Session for that student. Coach accept/alternate of an existing pending BookingRequest MUST establish the link when missing rather than failing solely due to a missing relationship. Coach reject of a pending BookingRequest MUST NOT require an existing relationship.

#### Scenario: Link present allows request path
- **WHEN** an active link exists between coach and student
- **THEN** BookingRequest creation APIs for that pair are allowed subject to other validation

#### Scenario: Missing link blocks request creation
- **WHEN** no active link exists
- **THEN** BookingRequest creation for that pair is rejected

#### Scenario: Link present allows direct coach booking
- **WHEN** an active link exists between coach and student
- **THEN** coach book-for-student APIs for that pair remain allowed subject to other validation

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

### Requirement: Tag assignment requires an active coach–student link
The system SHALL require an active coach–student relationship before a coach may assign one of their tags to a student user.

#### Scenario: Link present allows tag assign
- **WHEN** an active link exists between coach and student
- **THEN** tag assignment APIs for that pair are allowed (subject to ownership of the tag)

#### Scenario: Missing link blocks tag assign
- **WHEN** no active link exists
- **THEN** tag assignment requests for that pair are rejected

