## ADDED Requirements

### Requirement: Trainer creates recurring schedule in Russian UI
The mobile app SHALL provide a Russian coach flow to create a RecurringBooking for a linked student: weekday chips (Monday-first), local start time, mode `online`/`offline`, and confirm. The flow MUST call the recurring-bookings API, show loading/error states, and display the initial sync summary including booked count and conflicts. UI MUST reuse existing design-system primitives (`FyButton`, `FyCard`, `FyInputCard`, day-of-week chips) and MUST NOT introduce Riverpod or other state libraries.

#### Scenario: Trainer submits valid series
- **WHEN** a trainer selects a linked student, weekdays, time and mode and confirms
- **THEN** the app creates the series, shows how many trainings were booked, and lists any conflicts

#### Scenario: Unlinked student not offered
- **WHEN** the trainer opens student selection for a recurring series
- **THEN** only actively linked students are available

### Requirement: Trainer reviews series detail and conflicts
The app SHALL show a series detail screen with pattern summary, status, upcoming materialized sessions when available, and a conflicts section. For each conflict the trainer MUST be able to skip the date or reschedule to another local time/date, then refresh sync results. Cancel series MUST require confirmation and refresh the list.

#### Scenario: Resolve conflict by reschedule
- **WHEN** a trainer opens a `missing_slot` or `booked_other` conflict and submits a valid reschedule
- **THEN** the app calls resolve, refreshes the series, and the conflict is removed when booking succeeds

#### Scenario: Cancel series
- **WHEN** a trainer confirms cancellation of an active series
- **THEN** the app cancels via API and the series appears cancelled in the list

### Requirement: Entry from schedule workspace
The trainer schedule workspace SHALL expose an entry point to recurring booking (from relationship/student context and/or schedule actions) without adding a new bottom-navigation tab. One-off book-for-student and BookingRequest flows MUST remain available.

#### Scenario: Open recurring from schedule
- **WHEN** a trainer chooses «Регулярный график» (or equivalent) for a linked student
- **THEN** the create/list recurring flow opens inside the existing authenticated shell
