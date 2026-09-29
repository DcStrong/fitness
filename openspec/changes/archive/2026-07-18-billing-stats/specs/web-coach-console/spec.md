## ADDED Requirements

### Requirement: Console shell exposes trainer finance navigation
The authenticated web coach console SHALL include Russian navigation to a finance page where the trainer can view summary, debts, ledger, and finance actions.

#### Scenario: Trainer opens finance from shell
- **WHEN** a signed-in trainer selects «Финансы»
- **THEN** the console navigates to `/finance`

### Requirement: Session actions reflect payment state
The web sessions UI SHALL show tracked price/payment state, support mark-paid for earned pending charges, and require a charge decision for no-show.

#### Scenario: Outstanding session shown
- **WHEN** an earned pending Session appears in the sessions list
- **THEN** the trainer sees its amount, outstanding status, and mark-paid action
