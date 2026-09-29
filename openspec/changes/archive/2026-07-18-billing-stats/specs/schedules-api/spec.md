## ADDED Requirements

### Requirement: Linked student sees coach session price before booking
Open-slot responses for a linked coach SHALL include the coach's current positive default session price and currency when finance settings are configured.

#### Scenario: Price displayed with open slot
- **WHEN** a linked student lists a coach's open slots and the coach configured finance settings
- **THEN** each response provides the price/currency that self-booking will snapshot

#### Scenario: Coach has no configured price
- **WHEN** a linked student lists slots for a coach without finance settings
- **THEN** the response indicates price is not configured and booking cannot complete
