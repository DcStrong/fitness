## ADDED Requirements

### Requirement: Trainer configures a positive default session price
The system SHALL allow a trainer with `finance:manage_settings` to configure a positive default session price in minor currency units. MVP currency SHALL be `RUB`.

#### Scenario: Trainer saves default price
- **WHEN** a trainer saves a positive default session price
- **THEN** future self-bookings against that trainer use the configured price

#### Scenario: Booking without configured price is rejected
- **WHEN** a new booking targets a trainer without a positive finance setting
- **THEN** the system rejects booking with an actionable error

### Requirement: Booking creates an immutable session charge snapshot
Every new successful booking SHALL atomically create exactly one `pending` charge linked to the Session, containing the coach, student, amount, and currency snapshot. Later price-setting changes MUST NOT alter existing charges.

#### Scenario: Student booking snapshots default price
- **WHEN** a student successfully books a linked coach whose default price is configured
- **THEN** the new Session has one pending charge with that price and currency

#### Scenario: Trainer override is isolated to one session
- **WHEN** a trainer books for a linked student with an allowed positive price override
- **THEN** that charge uses the override without changing the trainer default

### Requirement: Earned and paid are distinct
A charge SHALL become earned when its Session is completed or when a no-show is explicitly chargeable. A charge MUST remain unpaid until the trainer records payment.

#### Scenario: Completed session becomes outstanding
- **WHEN** a booked Session transitions to completed
- **THEN** its pending charge receives `earnedAt` and is included in accrued/outstanding totals

#### Scenario: Completion does not imply payment
- **WHEN** a Session is completed
- **THEN** its charge does not become paid automatically

### Requirement: Trainer records full payment manually
The system SHALL allow a trainer with `finance:mark_paid` to mark an earned pending charge paid with method `cash`, `transfer`, `card`, or `other`. The status update and income ledger entry MUST be atomic and duplicate income MUST NOT be created.

#### Scenario: Cash payment recorded
- **WHEN** the trainer marks an earned charge paid with method `cash`
- **THEN** the charge is paid and exactly one linked income entry exists

#### Scenario: Unearned charge cannot be paid
- **WHEN** the trainer attempts to mark a booked but not earned charge paid
- **THEN** the system rejects the request

### Requirement: Student reads only own charge summary
A student with `finance:read_own_charge` SHALL be able to read amount, currency, and payment status for Sessions where they are the student. They MUST NOT receive the trainer's aggregate finances or other students' charges.

#### Scenario: Student sees own payment state
- **WHEN** a student lists their Sessions
- **THEN** tracked Sessions include their own price and payment status

#### Scenario: Student cannot read trainer wallet
- **WHEN** a student requests trainer finance summary or ledger
- **THEN** the system rejects the request

### Requirement: Legacy sessions are explicitly not tracked
Sessions created before finance tracking that have no charge SHALL return financial state `not_tracked`; the system MUST NOT invent a zero or historical price.

#### Scenario: Old session has no charge
- **WHEN** a legacy Session without a charge is returned
- **THEN** its finance summary is `not_tracked`
