## MODIFIED Requirements

### Requirement: Trainer configures a positive default session price
The system SHALL allow a trainer with `finance:manage_settings` to configure a positive default session price in minor currency units. MVP currency SHALL be `RUB`. Student BookingRequest creation and direct coach booking MUST be rejected when no positive setting is available.

#### Scenario: Trainer saves default price
- **WHEN** a trainer saves a positive default session price
- **THEN** future BookingRequests snapshot that quote and future direct coach bookings use the configured price unless an allowed override is supplied

#### Scenario: Request without configured price is rejected
- **WHEN** a new BookingRequest targets a trainer without a positive finance setting
- **THEN** the system rejects request creation with an actionable error

### Requirement: Booking creates an immutable session charge snapshot
Every accepted BookingRequest and successful direct coach booking SHALL atomically create exactly one `pending` charge linked to the Session. Request acceptance MUST use the immutable amount/currency quoted at request creation. Direct coach booking SHALL use the current default or allowed positive override. Later settings changes MUST NOT alter request quotes or existing charges.

#### Scenario: Request snapshots quote before charge
- **WHEN** a student creates a valid BookingRequest
- **THEN** the request stores amount/currency but no SessionCharge is created

#### Scenario: Accepted request uses quoted price
- **WHEN** the coach's default price changes after request creation and the request is later accepted
- **THEN** the new Session has one pending charge using the original request quote

#### Scenario: Terminal request has no charge
- **WHEN** a request is rejected, withdrawn, or expired
- **THEN** no SessionCharge exists for that request

#### Scenario: Trainer override is isolated to one direct session
- **WHEN** a trainer directly books for a linked student with an allowed positive price override
- **THEN** that charge uses the override without changing the trainer default
