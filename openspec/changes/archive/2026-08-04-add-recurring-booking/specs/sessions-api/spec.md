## ADDED Requirements

### Requirement: Recurring materialization creates coach-booked sessions
When recurring-booking sync books an occurrence, the system SHALL create a Session with status `booked`, `createdBy=coach`, the linked student, the matched schedule slot snapshot (time/mode), and SHALL create the Session charge atomically using the same quoting rules as direct book-for-student. The Session MUST store references to the RecurringBooking and occurrence local date for idempotency.

#### Scenario: Charge created with recurring session
- **WHEN** recurring sync successfully books an open slot for a student
- **THEN** a booked Session and its charge exist exactly as for trainer book-for-student

#### Scenario: Idempotent by occurrence date
- **WHEN** a Session already exists for the same recurring booking and local date
- **THEN** sync does not create a second Session for that occurrence

### Requirement: Recurring cancellation uses session lifecycle for future booked rows
When a RecurringBooking is cancelled, the system SHALL cancel each future Session of that series that is still `booked` using the existing cancel lifecycle transition and history audit. Sessions in terminal states MUST NOT be modified.

#### Scenario: Only future booked are cancelled
- **WHEN** a series is cancelled and it has one completed past Session and one future booked Session
- **THEN** the completed Session stays completed and the future Session becomes cancelled
