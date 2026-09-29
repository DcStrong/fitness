## ADDED Requirements

### Requirement: Session lifecycle debits session package when applicable
In addition to existing charge and history behavior, transitioning a Session from `booked` to `completed`, or to `no_show` with a chargeable decision, SHALL trigger at most one SessionPackage debit for the coach–student pair per the session-packages rules. Cancel and non-chargeable no_show MUST NOT debit a package. Package absence MUST NOT block the lifecycle transition.

#### Scenario: Complete still succeeds without package
- **WHEN** a coach completes a Session for a student with no session package
- **THEN** the Session becomes `completed` and no package debit occurs

#### Scenario: Complete debits package when present
- **WHEN** a coach completes a Session and an active package exists for that pair
- **THEN** the Session becomes `completed` and the package remaining decreases by one subject to package rules

#### Scenario: Cancel does not debit package
- **WHEN** a coach or student cancels a booked Session
- **THEN** the Session becomes `cancelled` and package remaining is unchanged
