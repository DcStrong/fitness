## MODIFIED Requirements

### Requirement: Trainer creates recurring schedule in Russian UI
The mobile app SHALL provide a Russian coach flow to create a RecurringBooking for a linked student: weekday chips (Monday-first), local start time, mode `online`/`offline`, optional horizon in weeks (`horizonWeeksOverride`, bounds 1–52, defaulting to coach schedule settings horizon when available), and confirm. The flow MUST call the recurring-bookings API, show loading/error states, and display the initial sync summary including booked count, slots created when returned by the API, and conflicts. UI MUST reuse existing design-system primitives (`FyButton`, `FyCard`, `FyInputCard`, day-of-week chips) and MUST NOT introduce Riverpod or other state libraries.

#### Scenario: Trainer submits valid series
- **WHEN** a trainer selects a linked student, weekdays, time and mode and confirms
- **THEN** the app creates the series, shows how many trainings were booked (and slots created when present), and lists any conflicts

#### Scenario: Unlinked student not offered
- **WHEN** the trainer opens student selection for a recurring series
- **THEN** only actively linked students are available

#### Scenario: Trainer sets a longer horizon
- **WHEN** a trainer sets horizon to 12 weeks and confirms
- **THEN** the create request includes `horizonWeeksOverride` 12

### Requirement: Trainer reviews series detail and conflicts
The app SHALL show a series detail screen with pattern summary, status, sync summary (including `slotsCreated` when provided), upcoming materialized sessions when available, and a conflicts section. Conflict reasons MUST be localized, including `mode_mismatch` as distinct from missing availability. For each resolvable conflict the trainer MUST be able to skip the date or reschedule to another local time/date, then refresh sync results. Cancel series MUST require confirmation and refresh the list.

#### Scenario: Resolve conflict by reschedule
- **WHEN** a trainer opens a `booked_other`, `overlap`, or `mode_mismatch` conflict and submits a valid reschedule
- **THEN** the app calls resolve, refreshes the series, and the conflict is removed when booking succeeds

#### Scenario: Sync shows slots created
- **WHEN** a sync response includes `slotsCreated` greater than zero
- **THEN** the detail UI shows that count in the Russian sync summary

#### Scenario: Cancel series
- **WHEN** a trainer confirms cancellation of an active series
- **THEN** the app cancels via API and the series appears cancelled in the list

### Requirement: Entry from schedule workspace
The trainer schedule workspace SHALL expose recurring booking through the calendar create-actions label «Регулярные тренировки» (not «Регулярный график» as trainer-availability wording) without adding a new bottom-navigation tab. One-off book-for-student and BookingRequest flows MUST remain available.

#### Scenario: Open recurring from create actions
- **WHEN** a trainer chooses «Регулярные тренировки»
- **THEN** the create/list recurring flow opens inside the existing authenticated shell
