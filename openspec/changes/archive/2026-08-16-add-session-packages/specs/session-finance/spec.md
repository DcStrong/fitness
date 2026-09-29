## ADDED Requirements

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
