## ADDED Requirements

### Requirement: Web console exposes trainer finance dashboard
The web console SHALL provide a Russian `/finance` page with period controls and summary cards for accrued, received, outstanding, expenses, and net.

#### Scenario: Trainer opens current month dashboard
- **WHEN** an authenticated trainer opens `/finance`
- **THEN** the page loads the current-month summary from the finance API

### Requirement: Web console exposes debts and ledger
The finance page SHALL show outstanding Session charges and an append-only ledger with period/type/student filters.

#### Scenario: Trainer filters debts by student
- **WHEN** a trainer selects a linked student
- **THEN** only that student's outstanding charges are displayed

### Requirement: Trainer performs finance actions on web
The web console SHALL allow configuring default price, marking an earned charge paid, recording an expense, and appending a correction/reversal where supported.

#### Scenario: Trainer records transfer payment
- **WHEN** a trainer marks an outstanding charge paid by transfer
- **THEN** the dashboard, debt list, and ledger refresh consistently

### Requirement: Web no-show action captures billing decision
When marking a Session no-show, the web console SHALL require the trainer to choose whether the Session is chargeable.

#### Scenario: Chargeable no-show
- **WHEN** the trainer confirms a no-show with charge enabled
- **THEN** the Session becomes no-show and its charge becomes earned
