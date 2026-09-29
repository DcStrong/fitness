# session-finance Specification

## Purpose
TBD - created by archiving change billing-stats. Update Purpose after archive.
## Requirements
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

### Requirement: Session packages do not replace session charges
Issuing or debiting a SessionPackage MUST NOT remove the requirement to create a SessionCharge on booking, MUST NOT auto-mark charges paid, and MUST NOT create finance ledger income. Pay-per-session charge earn/pay/cancel rules remain as specified for Session lifecycle. A package is a session-count entitlement tracked separately from money.

#### Scenario: Booking with active package still creates charge
- **WHEN** a coach books a Session for a student who has an active session package
- **THEN** exactly one pending SessionCharge is created for that Session as in existing booking rules

#### Scenario: Package debit does not mark charge paid
- **WHEN** a Session is completed and the active package is debited
- **THEN** the SessionCharge becomes earned per existing rules and does not become paid solely because of the package debit

#### Scenario: Package create does not create ledger income
- **WHEN** a coach creates or extends a SessionPackage
- **THEN** no finance ledger income entry is created by that action alone

