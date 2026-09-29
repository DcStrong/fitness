## MODIFIED Requirements

### Requirement: Trainer can add one-off free time from calendar
The calendar SHALL expose one-off free-time creation through the shared create-actions entry (FAB «+» → «Свободное время»), not as the sole primary FAB label. The form MUST collect local date, start, end and `online|offline` mode and MUST reject an end that is not after the start. The action MUST NOT use the domain label «Добавить слот». Prefill from an empty-hour tap MAY supply date and start.

#### Scenario: Free time reachable from create menu
- **WHEN** the trainer opens the calendar create-actions sheet
- **THEN** «Свободное время» is available alongside student booking actions

#### Scenario: Trainer creates free time
- **WHEN** the trainer submits a valid future local date, start, end and mode
- **THEN** the app creates the slot, closes the form, refreshes the visible period and focuses the created date

#### Scenario: Trainer enters invalid interval
- **WHEN** the submitted end is not after the start
- **THEN** the app shows an inline Russian validation error and does not call the API

#### Scenario: Slot creation fails
- **WHEN** the API rejects the new interval because of a conflict or network error
- **THEN** the form remains recoverable and shows a Russian error without claiming that free time was created

### Requirement: Day mode shows a selected-date timeline agenda
Day mode SHALL match the agreed mockup layout: a horizontal seven-day date strip for the week containing the selected local date, a localized day title under the strip, and a vertically scrollable hour timeline for that date. Event cards MUST be placed on the timeline by start/end time with a left accent bar and type-specific soft fill. Day mode MUST NOT render as a flat list of cards with only a centered date string and chevrons. Overlapping events MUST remain readable on a narrow phone and MUST NOT require horizontal desktop columns. Tapping empty hour regions MUST offer coach create actions (at least book student and free time) with the hour prefilled. Tapping an open availability card MUST open slot actions including booking a student.

#### Scenario: Day mode chrome matches mockup
- **WHEN** the trainer is in «День» mode
- **THEN** the UI shows the seven-day date strip, a day title such as «Пятница, 19 июля», and an hour timeline rather than only «21 июля 2026» with previous/next chevrons

#### Scenario: Trainer selects a date on the strip
- **WHEN** the trainer activates another date cell on the strip
- **THEN** that local date becomes selected, the day title updates, and the timeline shows only that day's events

#### Scenario: Current local date appears on the strip
- **WHEN** the strip week contains the device's current local date
- **THEN** that cell is labelled «Сегодня» and remains distinguishable when selected

#### Scenario: Selected day has multiple event types
- **WHEN** the selected date contains Sessions, free availability and pending requests
- **THEN** the timeline renders cards at their time offsets with interval, type/status label and relevant participant or mode information

#### Scenario: Events overlap
- **WHEN** two source records overlap in time but are not the same held/booked slot
- **THEN** day mode stacks readable event cards in the timeline column instead of shrinking them into narrow side-by-side columns

#### Scenario: Selected day is empty
- **WHEN** the selected local date contains no visible events
- **THEN** day mode keeps the strip and day title and shows a concise Russian empty state while create actions remain available

#### Scenario: Empty hour opens create actions
- **WHEN** the trainer taps an empty hour row on the day timeline
- **THEN** the app opens create/booking actions with that local start prefilled

#### Scenario: Open slot opens slot actions
- **WHEN** the trainer taps a free-time availability card
- **THEN** the app offers booking a linked student (and related slot actions) rather than doing nothing

## ADDED Requirements

### Requirement: Calendar create FAB opens a three-action sheet
On the «Календарь» tab the primary FAB SHALL be a create control («+» / «Добавить») that opens a Russian action sheet with: «Записать ученика», «Регулярные тренировки», and «Свободное время». The AppBar MUST NOT use «Регулярный график» as the sole recurring entry. The FAB MUST remain hidden on «Заявки» and «Доступность» tabs unless product copy explicitly requires otherwise (default: calendar tab only).

#### Scenario: FAB opens create sheet
- **WHEN** the trainer taps the calendar create FAB
- **THEN** the three actions above are shown

#### Scenario: Recurring from create sheet
- **WHEN** the trainer chooses «Регулярные тренировки»
- **THEN** the recurring list/create flow opens inside the authenticated shell
