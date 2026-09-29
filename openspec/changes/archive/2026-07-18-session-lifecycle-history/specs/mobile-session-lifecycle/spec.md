## ADDED Requirements

### Requirement: User can complete cancel or mark no_show from sessions UI
The mobile app SHALL show Russian actions on a `booked` session according to role: coach — complete / cancel / no-show; student — cancel. After success the list refreshes and shows the new status.

#### Scenario: Coach completes from UI
- **WHEN** a coach confirms «Завершить» on a booked session
- **THEN** the app calls complete API and shows status `completed`

#### Scenario: Student cancels from UI
- **WHEN** a student confirms «Отменить» on a booked session
- **THEN** the app calls cancel API and shows status `cancelled`

### Requirement: User can open session history
The mobile app SHALL let a participant open a history timeline for a session (Russian labels: кто, когда, переход статуса).

#### Scenario: History screen loads events
- **WHEN** the user opens history for a session they participate in
- **THEN** history events are listed chronologically
