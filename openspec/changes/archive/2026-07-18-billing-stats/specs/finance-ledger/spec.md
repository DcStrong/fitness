## ADDED Requirements

### Requirement: Trainer finance ledger is append-only
The system SHALL maintain an append-only ledger of trainer entries with type `income`, `expense`, or `adjustment`, amount in minor units, currency, occurrence time, and source metadata. Posted entries MUST NOT be edited or deleted.

#### Scenario: Posted entry remains immutable
- **WHEN** a ledger entry has been created
- **THEN** no API permits changing its amount, type, currency, or occurrence time

### Requirement: Session payment creates linked income
Marking a Session charge paid SHALL create one income ledger entry linked to that charge in the same database transaction.

#### Scenario: Payment transaction succeeds atomically
- **WHEN** mark-paid succeeds
- **THEN** both paid charge state and its income entry are committed

#### Scenario: Payment transaction fails atomically
- **WHEN** income insertion fails
- **THEN** the charge remains unpaid and no partial financial update persists

### Requirement: Trainer records manual expenses
The system SHALL allow a trainer with `finance:record_expense` to append a positive expense with optional category, note, and occurrence time.

#### Scenario: Cash expense recorded
- **WHEN** a trainer records a valid expense
- **THEN** an expense ledger entry appears in their ledger and period totals

### Requirement: Corrections preserve history
The system SHALL represent correction or reversal of a posted entry by appending an adjustment linked to the original entry, rather than mutating or deleting the original.

#### Scenario: Erroneous expense reversed
- **WHEN** a trainer reverses an erroneous expense
- **THEN** the original expense remains and a compensating adjustment is appended

### Requirement: Trainers access only their ledger
All ledger reads and writes MUST be scoped to the authenticated trainer.

#### Scenario: Foreign entry access denied
- **WHEN** a trainer attempts to read or reverse another trainer's entry
- **THEN** the system rejects the request
