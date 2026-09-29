## ADDED Requirements

### Requirement: Trainer Home exposes pending booking request count
The mobile Home dashboard SHALL independently load the authenticated trainer's non-expired pending BookingRequest count, display a compact actionable badge/card when the count is positive, and navigate to the trainer request inbox. Student Home MUST NOT expose trainer inbox UI.

#### Scenario: Trainer has pending requests
- **WHEN** the trainer Home successfully loads a pending count greater than zero
- **THEN** Home shows the count with a Russian «Заявки» action leading to the request inbox

#### Scenario: Trainer has no pending requests
- **WHEN** the pending count is zero
- **THEN** Home does not show a misleading urgent badge

#### Scenario: Count request fails
- **WHEN** the pending-count API fails while the daily Session request succeeds
- **THEN** the daily schedule and feature navigation remain usable and Home does not claim a zero count

#### Scenario: Student opens Home
- **WHEN** an authenticated student reaches Home
- **THEN** no trainer request count or inbox destination is shown

### Requirement: Home pending count refreshes after request decisions
The mobile app SHALL refresh the trainer Home pending count after returning from an inbox mutation or performing a manual Home refresh.

#### Scenario: Trainer accepts from inbox
- **WHEN** the trainer resolves a pending request and returns to Home
- **THEN** Home obtains an updated pending count rather than retaining the stale badge value
