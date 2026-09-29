## ADDED Requirements

### Requirement: Booking atomically creates financial snapshot
A successful new Session booking SHALL atomically create its Session charge using the coach's configured positive price. Student self-booking SHALL use the default price; trainer book-for-student MAY provide a positive one-session override.

#### Scenario: Booking and charge commit together
- **WHEN** booking succeeds
- **THEN** Session, slot status, and one pending charge with price snapshot are committed in the same transaction

#### Scenario: Charge creation fails
- **WHEN** charge persistence fails during booking
- **THEN** neither Session creation nor slot booking is committed

### Requirement: Session responses include scoped finance summary
Session responses SHALL include a finance summary with amount, currency, and charge status for participants allowed to read that charge. Legacy Sessions without a charge SHALL return `not_tracked`.

#### Scenario: Participant lists tracked Session
- **WHEN** the coach or student lists their tracked Sessions
- **THEN** each Session includes its own price and payment status

#### Scenario: Legacy Session listed
- **WHEN** a participant lists a Session created before finance tracking
- **THEN** its finance state is `not_tracked` rather than a fabricated zero price
