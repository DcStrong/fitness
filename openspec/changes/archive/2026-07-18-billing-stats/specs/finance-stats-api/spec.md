## ADDED Requirements

### Requirement: Trainer receives finance summary for an explicit period
The system SHALL allow a trainer with `finance:read_own` to request a summary using valid ISO `from` and `to` boundaries. The result SHALL include accrued, received, outstanding, expenses, adjustments, net, currency, and relevant counts.

#### Scenario: Monthly summary
- **WHEN** a trainer requests the UTC boundaries of their current month
- **THEN** the API returns totals calculated from their charges and ledger entries for that period

#### Scenario: Invalid range rejected
- **WHEN** `to` is not after `from` or either boundary is invalid
- **THEN** the system rejects the request

### Requirement: Summary distinguishes accrued and received money
`accrued` SHALL use earned charge timestamps; `received` SHALL use income ledger occurrence timestamps. Completing a Session MUST NOT increase received until payment is recorded.

#### Scenario: Completed unpaid session
- **WHEN** a Session is completed in the selected period but remains unpaid
- **THEN** accrued and outstanding increase while received does not

### Requirement: Net cash is derived from ledger
The summary SHALL calculate net as received income minus expenses plus signed adjustments. The system MUST NOT rely on a separately mutable balance field.

#### Scenario: Expense reduces net
- **WHEN** an expense occurs in the selected period
- **THEN** expenses increase and net decreases by the same amount

### Requirement: Trainer can list ledger and debts
The system SHALL expose the trainer's ledger filtered by period/type and a list of earned pending charges (debts), with optional student filtering.

#### Scenario: Debts list excludes unearned bookings
- **WHEN** the trainer requests debts
- **THEN** booked Sessions without `earnedAt` are not returned

#### Scenario: Student filter scopes results
- **WHEN** a trainer requests debts for one linked student
- **THEN** only that trainer's outstanding charges for the selected student are returned
