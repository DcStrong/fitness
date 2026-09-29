## ADDED Requirements

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
