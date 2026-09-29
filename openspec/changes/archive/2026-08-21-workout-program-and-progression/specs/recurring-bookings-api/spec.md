## ADDED Requirements

### Requirement: Recurring booking exposes and persists its workout program
The system SHALL allow the owning coach to GET and PUT the workout program as a subresource of the RecurringBooking. GET of the series MAY include a summary that a program exists and the count of day items. Cancelled series MUST reject program upsert. Recurring sync MUST apply an existing program to newly booked occurrences in the current horizon.

#### Scenario: Get program after upsert
- **WHEN** the coach PUTs a valid program and then GETs it
- **THEN** weekdays, template ids, student copy ids, horizon, and progression rules are returned

#### Scenario: Sync applies program
- **WHEN** sync creates a new booked occurrence for a weekday that has program items
- **THEN** that session receives those workout items and snapshots

#### Scenario: Cancelled series cannot upsert program
- **WHEN** the coach PUTs a program on a cancelled series
- **THEN** the system rejects the request
