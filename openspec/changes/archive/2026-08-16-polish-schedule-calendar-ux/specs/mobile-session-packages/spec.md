## ADDED Requirements

### Requirement: Trainer filters students by payment and pending-request status
On the trainer «Ученики и абонементы» list the app SHALL provide Russian filter chips: «Все», «Оплачен», «Не оплачен», «Ожидает». Categorization MUST be mutually exclusive with priority: (1) **Ожидает** — the student has at least one non-expired pending BookingRequest in the trainer inbox; (2) **Оплачен** — the student has an `active` SessionPackage; (3) **Не оплачен** — linked student without an active package. Default filter is «Все». Loading MUST use existing relationships, packages, and booking-requests inbox APIs without a new Nest endpoint.

#### Scenario: Filter paid students
- **WHEN** a trainer selects «Оплачен»
- **THEN** only linked students with an active package are listed

#### Scenario: Filter unpaid students
- **WHEN** a trainer selects «Не оплачен»
- **THEN** only linked students without an active package and without a pending inbox request (per priority rules) are listed

#### Scenario: Filter waiting students
- **WHEN** a trainer selects «Ожидает»
- **THEN** students who have a pending booking request awaiting trainer response are listed

#### Scenario: Pending outranks package
- **WHEN** a linked student has both an active package and a pending booking request
- **THEN** that student appears under «Ожидает» and not under «Оплачен» while the waiting filter semantics apply
