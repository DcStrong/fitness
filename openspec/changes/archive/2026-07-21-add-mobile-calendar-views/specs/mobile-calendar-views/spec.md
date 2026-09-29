## ADDED Requirements

### Requirement: Trainer calendar provides day, week and month modes
The Flutter app SHALL provide an authenticated trainer calendar with selectable `day`, `week`, and `month` modes. The selected mode and selected local date MUST remain stable while the trainer switches among schedule feature tabs within the mounted `/schedule` destination.

#### Scenario: Calendar opens for trainer
- **WHEN** an authenticated trainer opens the primary «Расписание» destination for the first time
- **THEN** the app shows the «Календарь» tab in «День» mode with the current local date selected

#### Scenario: Trainer changes calendar mode
- **WHEN** the trainer selects «Неделя» or «Месяц»
- **THEN** the visible period changes to the selected mode without navigating away from the «Расписание» destination

#### Scenario: Trainer returns from another schedule tab
- **WHEN** the trainer switches from «Календарь» to «Заявки» or «Доступность» and then returns
- **THEN** the previously selected calendar mode and date are restored while the schedule feature remains mounted

### Requirement: Calendar mode toolbar stays sticky while scrolling
The `День / Неделя / Месяц` mode control and its period navigation chrome SHALL remain pinned above the scrollable calendar body in day, week and month modes so the trainer can change mode or period without scrolling back to the top.

#### Scenario: Trainer scrolls day timeline
- **WHEN** the trainer scrolls the day timeline or date strip content vertically
- **THEN** the mode segmented control remains visible above the scrolling body

#### Scenario: Trainer scrolls week or month body
- **WHEN** the trainer scrolls the week overview or month grid/agenda vertically
- **THEN** the mode segmented control remains visible above the scrolling body

### Requirement: Calendar combines schedule event types without duplicates
The trainer calendar SHALL normalize booked Sessions, open availability slots and pending booking requests into one chronological projection. It MUST render a booked slot through its Session only, and a held slot through its pending request rather than simultaneously claiming that the same time is free.

#### Scenario: Open slot has no request or Session
- **WHEN** an open slot in the visible period is not held or booked
- **THEN** the calendar shows it as «Свободно» using the availability presentation

#### Scenario: Slot has a booked Session
- **WHEN** a Session references a slot in the visible period
- **THEN** the calendar shows one training event and does not show a second free event for that slot

#### Scenario: Pending request holds a slot
- **WHEN** a pending booking request references a slot in the visible period
- **THEN** the calendar shows one «Ожидает решения» request event and does not show that held time as free

#### Scenario: Event types are distinguishable
- **WHEN** a period contains a Session, free availability and a pending request
- **THEN** each type has a consistent label and visual treatment and is not distinguished by color alone

### Requirement: Day mode shows a selected-date timeline agenda
Day mode SHALL match the agreed mockup layout: a horizontal seven-day date strip for the week containing the selected local date, a localized day title under the strip, and a vertically scrollable hour timeline for that date. Event cards MUST be placed on the timeline by start/end time with a left accent bar and type-specific soft fill. Day mode MUST NOT render as a flat list of cards with only a centered date string and chevrons. Overlapping events MUST remain readable on a narrow phone and MUST NOT require horizontal desktop columns.

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
- **THEN** day mode keeps the strip and day title and shows a concise Russian empty state while «Свободное время» remains available

### Requirement: Requests tab shows a pending count badge
The schedule workspace «Заявки» tab SHALL display a numeric badge with the number of pending booking requests visible to the trainer when that count is greater than zero.

#### Scenario: Pending requests exist
- **WHEN** the trainer has three pending booking requests
- **THEN** the «Заявки» tab shows a badge with `3`

#### Scenario: No pending requests
- **WHEN** the trainer has zero pending booking requests
- **THEN** the «Заявки» tab shows no numeric badge

### Requirement: Week mode uses a mobile-first seven-day overview
Week mode SHALL represent the Monday-through-Sunday local week as seven vertical day summaries with event counts/type indicators. Selecting a day SHALL reveal a compact agenda preview without converting the screen into a seven-column desktop grid.

#### Scenario: Week contains events
- **WHEN** the visible week loads successfully
- **THEN** each day row shows its local weekday/date and a concise summary of events for that day

#### Scenario: Trainer selects a week day
- **WHEN** the trainer activates a day row
- **THEN** that day becomes selected and its chronological agenda preview is shown

#### Scenario: Week crosses a month boundary
- **WHEN** the Monday-through-Sunday range spans two calendar months
- **THEN** all seven local dates are shown once under the same week range

### Requirement: Month mode uses indicators and selected-day agenda
Month mode SHALL show a Monday-first calendar grid for the anchor month. Date cells SHALL contain compact semantic indicators for present event types, while full event details SHALL be rendered only in the agenda for the selected date.

#### Scenario: Month contains mixed events
- **WHEN** dates in the visible month contain different event types
- **THEN** their cells show the corresponding training, free and request indicators with an accessible legend

#### Scenario: Trainer selects a month date
- **WHEN** the trainer activates a date cell
- **THEN** the cell becomes selected and the agenda below the grid shows that date's events

#### Scenario: Adjacent-month cell is selected
- **WHEN** the grid exposes an adjacent-month date and the trainer selects it
- **THEN** the calendar moves to that date's month and keeps the selected date visible

### Requirement: Period navigation uses local calendar boundaries
The calendar SHALL load half-open visible ranges calculated in device-local calendar time and serialized as UTC API boundaries. Day, week and month navigation MUST use calendar dates rather than fixed-hour durations, and the trainer SHALL be able to return to today.

#### Scenario: Trainer moves to next period
- **WHEN** the trainer activates next in day, week or month mode
- **THEN** the anchor moves by one local calendar day, one Monday-through-Sunday week or one calendar month respectively and loads that exact range

#### Scenario: Trainer returns to today
- **WHEN** the visible period does not contain the current local date and the trainer activates «Сегодня»
- **THEN** the current local date becomes selected and visible

#### Scenario: Local day has a DST transition
- **WHEN** a visible local day is shorter or longer than 24 hours
- **THEN** the API range still starts at that local midnight and ends at the next local midnight after separate UTC conversion

### Requirement: Trainer can add one-off free time from calendar
The calendar SHALL expose a bottom-right pill FAB labelled «+ Свободное время» (or equivalent «Добавить свободное время») that creates one open availability slot through the existing schedule API. The form MUST collect local date, start, end and `online|offline` mode and MUST reject an end that is not after the start. The action MUST NOT use the domain label «Добавить слот».

#### Scenario: Free-time FAB is visible in day mode
- **WHEN** the trainer views the calendar
- **THEN** a labelled pill FAB «+ Свободное время» is available

#### Scenario: Trainer creates free time
- **WHEN** the trainer submits a valid future local date, start, end and mode
- **THEN** the app creates the slot, closes the form, refreshes the visible period and focuses the created date

#### Scenario: Trainer enters invalid interval
- **WHEN** the submitted end is not after the start
- **THEN** the app shows an inline Russian validation error and does not call the API

#### Scenario: Slot creation fails
- **WHEN** the API rejects the new interval because of a conflict or network error
- **THEN** the form remains recoverable and shows a Russian error without claiming that free time was created

### Requirement: Calendar handles loading, errors and refresh
The calendar SHALL expose loading, populated, empty, failure and manual-refresh behavior. A booking-request source failure MUST NOT hide successfully loaded Sessions and availability, but the UI MUST warn that request indicators may be incomplete.

#### Scenario: Required calendar sources fail initially
- **WHEN** Sessions or own availability cannot be loaded and no previous calendar data exists
- **THEN** the calendar shows an error state with retry

#### Scenario: Request source alone fails
- **WHEN** Sessions and availability load but pending requests fail
- **THEN** calendar events remain usable and a compact warning with refresh is shown

#### Scenario: Trainer refreshes populated calendar
- **WHEN** the trainer manually refreshes the visible period
- **THEN** current content remains visible until the replacement projection succeeds or a refresh error is reported

### Requirement: Calendar preserves trainer app navigation
The calendar SHALL run inside the existing trainer shell whose primary destinations are «Главная», «Расписание», «Ученики» and «Профиль». Schedule-local tabs MUST NOT add «Сообщения» or «Аналитика» as app destinations.

#### Scenario: Trainer opens calendar
- **WHEN** the calendar is visible
- **THEN** «Расписание» is the selected bottom destination and the other existing trainer destinations remain available

#### Scenario: Narrow phone renders calendar
- **WHEN** the available width is a narrow supported phone width
- **THEN** top tabs, mode control, date strip or period navigation and timeline/event content remain operable without horizontal page overflow
