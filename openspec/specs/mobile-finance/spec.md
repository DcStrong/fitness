# mobile-finance Specification

## Purpose
TBD - created by archiving change billing-stats. Update Purpose after archive.
## Requirements
### Requirement: Trainer manages finance settings and payments on mobile
The Flutter app SHALL provide Russian UI for a trainer to set the default session price, view charge state, mark earned charges paid with a payment method, and choose whether a no-show is chargeable.

#### Scenario: Trainer marks cash payment
- **WHEN** a trainer selects an outstanding Session and confirms cash payment
- **THEN** the app records payment and refreshes charge/summary state

#### Scenario: Trainer chooses no-show without charge
- **WHEN** a trainer marks no-show and answers that no fee applies
- **THEN** the app sends the explicit non-chargeable decision

### Requirement: Trainer views wallet summary on mobile
The Flutter app SHALL provide day, week, month, and custom-period finance summaries showing accrued, received, outstanding, expenses, and net.

#### Scenario: Trainer selects current week
- **WHEN** the trainer selects the week preset
- **THEN** the app requests the corresponding ISO period and displays returned totals

### Requirement: Trainer records expenses on mobile
The Flutter app SHALL allow a trainer to append an expense with amount and optional category/note.

#### Scenario: Trainer saves expense
- **WHEN** a trainer submits a valid expense
- **THEN** it appears in the ledger and summary refreshes

### Requirement: Student sees own session price and payment status
The Flutter app SHALL show a student the price and payment status only for their own tracked Sessions.

#### Scenario: Student opens own session
- **WHEN** a student views a tracked Session
- **THEN** the app shows its amount, currency, and payment status without trainer aggregate data

