## ADDED Requirements

### Requirement: Finance permissions exist in catalog
The system SHALL include permission codes `finance:manage_settings`, `finance:read_own`, `finance:mark_paid`, `finance:record_expense`, `finance:adjust_own`, and `finance:read_own_charge`. The trainer role SHALL receive all trainer finance permissions; the student role SHALL receive only `finance:read_own_charge`.

#### Scenario: Trainer seed includes finance management
- **WHEN** seed runs
- **THEN** role `trainer` can configure price, read own finances, mark paid, record expense, and adjust own ledger

#### Scenario: Student seed is read-only and scoped
- **WHEN** seed runs
- **THEN** role `student` can read only financial summaries for their own Session charges

#### Scenario: Finance guards remain permission-based
- **WHEN** finance endpoints are protected
- **THEN** authorization checks permission codes plus resource ownership, not role-name equality alone
