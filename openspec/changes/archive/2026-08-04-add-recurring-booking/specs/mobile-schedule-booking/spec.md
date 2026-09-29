## ADDED Requirements

### Requirement: Trainer can open recurring booking from schedule workspace
The mobile schedule workspace SHALL expose a Russian entry point to create or manage RecurringBookings for linked students without adding a new bottom-navigation destination. One-off «Свободное время», BookingRequest inbox actions, and direct book-for-student MUST remain available alongside recurring flows.

#### Scenario: Entry does not replace one-off booking
- **WHEN** a trainer opens the schedule workspace
- **THEN** the trainer can still perform one-off free-time creation and one-off student booking in addition to opening the recurring schedule flow

#### Scenario: Recurring entry for linked student
- **WHEN** a trainer chooses the recurring-schedule action for a linked student
- **THEN** the app opens the mobile-recurring-booking create or list flow
