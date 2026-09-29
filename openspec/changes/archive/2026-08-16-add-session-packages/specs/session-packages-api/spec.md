## ADDED Requirements

### Requirement: Coach issues a session package to a linked student
The system SHALL allow the session coach to create a SessionPackage for an active coach–student relationship with a positive `totalSessions` count and optional `expiresAt`. Creation MUST fail when an `active` package already exists for that pair. Initial `remainingSessions` MUST equal `totalSessions` and status MUST be `active` when `expiresAt` is null or in the future.

#### Scenario: Create package for linked student
- **WHEN** a coach creates a package of 8 sessions for a linked student with no active package
- **THEN** an active package exists with `totalSessions=8` and `remainingSessions=8`

#### Scenario: Duplicate active package rejected
- **WHEN** a coach attempts to create a package while an active package already exists for that pair
- **THEN** the system rejects the request without creating a second active package

#### Scenario: Unlinked student rejected
- **WHEN** a coach attempts to create a package for a student without an active relationship
- **THEN** the system rejects the request

### Requirement: Participants can read package remaining count
The system SHALL allow the coach and the student of a package to list and read packages they participate in, including `remainingSessions`, `totalSessions`, `status`, and `expiresAt`. A coach MUST NOT read another coach's packages; a student MUST NOT read packages where they are not the student.

#### Scenario: Coach lists own packages
- **WHEN** a coach lists session packages
- **THEN** the response includes packages where they are the coach with remaining counts

#### Scenario: Student reads own remaining
- **WHEN** a student reads their active package with the linked coach
- **THEN** the response includes `remainingSessions` for that package

### Requirement: Coach extends or archives a package
The system SHALL allow the coach to extend a package by adding a positive number of sessions (increasing both `totalSessions` and `remainingSessions`) and optionally updating `expiresAt`. Extending an `exhausted` or `expired` package MUST return it to `active` when `remainingSessions > 0` and the package is not past expiry. The coach SHALL be able to archive a package, after which it MUST NOT accept further debits and MUST NOT count as the pair's active package.

#### Scenario: Extend adds remaining sessions
- **WHEN** a coach extends an active package with 4 remaining by adding 8 sessions
- **THEN** `remainingSessions` becomes 12 and `totalSessions` increases by 8

#### Scenario: Extend exhausted package reactivates
- **WHEN** a coach extends an exhausted package by adding sessions with a valid optional expiry
- **THEN** the package status becomes `active` with the new remaining count

#### Scenario: Archive freezes package
- **WHEN** a coach archives an active package with remaining sessions
- **THEN** status becomes `archived` and a new package may be created for the same pair

### Requirement: Qualifying session terminals debit the active package
When a Session for the package's coach–student pair transitions to `completed`, or to `no_show` with an explicit chargeable decision, the system SHALL decrement `remainingSessions` by 1 on the pair's active non-expired package in the same transaction, at most once per Session. Transition to `cancelled`, or `no_show` with a non-chargeable decision, MUST NOT debit. Booking or creating a `booked` Session MUST NOT debit. If no eligible package exists, lifecycle proceeds without package changes.

#### Scenario: Completed session decrements remaining
- **WHEN** a booked Session is completed and an active package has remaining 3
- **THEN** `remainingSessions` becomes 2 and a debit record exists for that Session

#### Scenario: Booked session does not debit
- **WHEN** a Session is created in `booked` status for a pair with an active package
- **THEN** `remainingSessions` is unchanged

#### Scenario: Cancel does not debit
- **WHEN** a booked Session is cancelled
- **THEN** `remainingSessions` is unchanged

#### Scenario: Chargeable no_show debits
- **WHEN** a coach marks no_show with chargeable decision and an active package has remaining 1
- **THEN** `remainingSessions` becomes 0 and status becomes `exhausted`

#### Scenario: Non-chargeable no_show does not debit
- **WHEN** a coach marks no_show with non-chargeable decision
- **THEN** `remainingSessions` is unchanged

#### Scenario: Debit is idempotent per session
- **WHEN** a completed Session's lifecycle debit is attempted again for the same Session
- **THEN** remaining is not decremented a second time

### Requirement: Exhaustion and expiry are visible to the coach
When a debit moves `remainingSessions` to 0, the package status SHALL become `exhausted` and the lifecycle (or package) response SHALL signal exhaustion so clients can prompt renewal. When `expiresAt` is in the past on read or before debit, an `active` package SHALL become `expired` and MUST NOT accept further debits. Exhaustion or expiry MUST NOT by itself cancel RecurringBooking sync or block new Session booking.

#### Scenario: Last session exhausts package
- **WHEN** a completed Session debits the last remaining session
- **THEN** package status is `exhausted` and the API signals package exhaustion to the coach client

#### Scenario: Expired package does not debit
- **WHEN** a Session is completed for a pair whose only package has `expiresAt` in the past
- **THEN** the package is `expired`, remaining is not decremented for that completion as an active debit, and the Session still completes

#### Scenario: Exhausted package does not block booking
- **WHEN** a coach books a new Session for a student whose package is exhausted
- **THEN** the Session is created successfully
