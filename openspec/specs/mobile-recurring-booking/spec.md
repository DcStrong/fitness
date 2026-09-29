# mobile-recurring-booking Specification

## Purpose
Flutter trainer flow for recurring bookings (Russian copy): create a weekday series for a linked student (optional horizon weeks), review series detail with sync summary including `slotsCreated`, resolve conflicts by skip/reschedule (including `mode_mismatch`), cancel or restore a series, and browse an enriched list with relative date labels. Entry via schedule AppBar/Home and calendar create-actions «Регулярные тренировки».

## Requirements

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
The app SHALL show a series detail screen with pattern summary, status, and sync summary (including `slotsCreated` when provided). When the trainer arrives from create with an initial sync summary, the app MUST display that summary without requiring an immediate sync tap. The primary exit control SHALL be «Готово» (return to schedule or list). Horizon materialization SHALL use a secondary control labeled «Обновить горизонт» with Russian copy explaining the series is already active and the action extends/refreshes bookings on the availability horizon. Conflict reasons MUST be localized, including `mode_mismatch` as distinct from missing availability. For each resolvable conflict the trainer MUST be able to skip the date (reschedule UI may remain deferred). Cancel series MUST require confirmation. Cancelled detail MUST NOT prompt to sync and MUST offer permanent delete; restore remains available per «Restore from archive».

#### Scenario: After create detail shows sync summary and Done
- **WHEN** create returns a sync summary and detail opens
- **THEN** the UI shows booked/slotsCreated/conflicts counts and a «Готово» action without requiring «Синхронизировать»

#### Scenario: Update horizon
- **WHEN** a trainer taps «Обновить горизонт» on an active series
- **THEN** the app calls sync and refreshes the summary

#### Scenario: Resolve conflict by skip
- **WHEN** a trainer skips a resolvable conflict date
- **THEN** the app calls resolve skip and refreshes the summary

#### Scenario: Cancel series
- **WHEN** a trainer confirms cancellation of an active series
- **THEN** the app cancels via API and the series leaves the active list (archive/cancelled)

#### Scenario: Delete cancelled series
- **WHEN** a trainer deletes a cancelled series from detail
- **THEN** the app calls delete and returns to the list without that series

### Requirement: Entry from schedule workspace
The trainer schedule workspace SHALL expose recurring booking through the calendar create-actions label «Регулярные тренировки» (not «Регулярный график» as trainer-availability wording) without adding a new bottom-navigation tab. One-off book-for-student and BookingRequest flows MUST remain available.

#### Scenario: Open recurring from create actions
- **WHEN** a trainer chooses «Регулярные тренировки»
- **THEN** the create/list recurring flow opens inside the existing authenticated shell

### Requirement: Active list and cancelled archive
The recurring list SHALL show active series by default and SHALL provide access to cancelled (archive) series. Archive entries MAY be opened, restored, or permanently deleted.

#### Scenario: Active list hides cancelled
- **WHEN** the trainer opens the recurring list
- **THEN** cancelled series are not shown in the primary active list

### Requirement: Discoverable entry to recurring list
The trainer schedule AppBar SHALL offer a control that navigates to `/schedule/recurring` (key `schedule-recurring-button`). The trainer Home feature cards SHALL include an entry «Регулярные тренировки» to the same route.

#### Scenario: Open list from schedule
- **WHEN** a trainer taps «Регулярные» on the schedule screen
- **THEN** the recurring bookings list opens

### Requirement: Rich recurring list and detail cards
List cards SHALL show student display name (fallback email or id), optional email subtitle, and weekdays · time · mode. For **active** cards the primary date line SHALL be the next occurrence (`nextOccurrenceLocalDate`) with time, using relative calendar labels; created date MAY appear as secondary meta. For **archive** cards the card SHALL show cancelled date when available (same relative labels). Detail SHALL show student name/email and the same date fields.

#### Scenario: List card shows student name
- **WHEN** the coach views the recurring list and an item has `studentDisplayName`
- **THEN** the card title is that name

#### Scenario: Active card shows next session date
- **WHEN** the coach views an active series with `nextOccurrenceLocalDate`
- **THEN** the card shows that date via relative calendar labels together with the series time

#### Scenario: Archive card shows cancelled date
- **WHEN** the coach views a cancelled series with `cancelledAt`
- **THEN** the card shows the cancelled date via relative calendar labels

### Requirement: Relative calendar labels
Wherever recurring list/detail shows calendar dates for next occurrence, created, or cancelled, the app SHALL format as: «сегодня» if the local calendar day is today, «завтра» if tomorrow, «вчера» if yesterday; otherwise `DD.MM.YY` (two-digit year).

#### Scenario: Today label
- **WHEN** a displayed date is today in local time
- **THEN** the label is «сегодня»

#### Scenario: Far date uses DD.MM.YY
- **WHEN** a displayed date is neither today, tomorrow, nor yesterday
- **THEN** the label is formatted as `DD.MM.YY`

### Requirement: Restore from archive
For a cancelled series the archive list and/or detail SHALL offer «Восстановить». On success the app SHALL refresh to active state (list and/or detail) and show feedback. On 409 with `existingId` the app SHALL show an error and MAY open the conflicting series.

#### Scenario: Restore cancelled from UI
- **WHEN** the coach taps «Восстановить» on a cancelled series and the API succeeds
- **THEN** the series is treated as active again in the UI

### Requirement: Create conflict opens existing series
When create returns HTTP 409 with `existingId`, the app SHALL show an error snackbar and navigate to that series detail.

#### Scenario: Duplicate create navigates to existing
- **WHEN** the coach submits create and the API returns 409 with `existingId`
- **THEN** a snackbar is shown and the existing series detail is opened

### Requirement: Recurring detail secondary actions use FySecondaryButton
Recurring booking detail (and create where applicable) non-primary actions SHALL use `FySecondaryButton` instead of raw `OutlinedButton`, while primary CTAs remain on the existing primary button primitives.

#### Scenario: Trainer sees skip or secondary conflict action
- **WHEN** recurring detail shows a non-primary action button
- **THEN** that control is a `FySecondaryButton` with Russian label unchanged

### Requirement: Recurring forms use shared chips and sheets
Weekday / mode selection on recurring create and any modal sheets in the recurring flow that match calendar patterns SHALL use `FyChip` and `showFyBottomSheet` respectively after migration.

#### Scenario: Trainer selects weekdays on create
- **WHEN** the trainer opens «Новые регулярные тренировки» and toggles weekdays
- **THEN** weekday chips are `FyChip`-based and selection still drives create payload weekdays

### Requirement: Series detail offers program setup
The Russian recurring series detail SHALL include a primary or secondary action «Программа» that opens the workout program screen for that series when the series is active. After creating a series the app MAY prompt to set the program rather than leaving the trainer on an empty split.

#### Scenario: Open program from detail
- **WHEN** a trainer taps «Программа» on an active series
- **THEN** the program screen opens for that recurring booking id

#### Scenario: Cancelled series hides upsert
- **WHEN** the series is cancelled
- **THEN** the detail does not offer saving a new program
