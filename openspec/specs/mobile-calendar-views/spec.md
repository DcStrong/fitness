# mobile-calendar-views Specification

## Purpose
Trainer-facing day/week/month calendar in the mobile schedule workspace: unified event projection, sticky mode chrome, pending badge, create-actions FAB (book student / recurring / free time), day-timeline taps that open booking or free-time flows, session manage actions, and omission of cancelled sessions from the event map.
## Requirements
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
Day mode SHALL match the agreed mockup layout: a horizontal seven-day date strip for the week containing the selected local date, previous/next day chevrons in the toolbar, a localized day title under the strip, and a vertically scrollable hour timeline for that date. Event cards MUST be placed on the timeline by start/end time with a left accent bar and type-specific soft fill. Day mode MUST NOT render as a flat list of cards with only a centered date string. Overlapping events MUST remain readable on a narrow phone and MUST NOT require horizontal desktop columns. Tapping empty hour regions MUST offer coach create actions (at least book student and free time) with the hour prefilled. Tapping an open availability card MUST open slot actions including booking a student.

#### Scenario: Day mode chrome matches mockup
- **WHEN** the trainer is in «День» mode
- **THEN** the UI shows the seven-day date strip, previous/next day controls, a day title such as «Пятница, 19 июля», and an hour timeline

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

### Requirement: Calendar create FAB opens a three-action sheet
On the «Календарь» tab the primary FAB SHALL be a create control («+» / «Добавить») that opens a Russian action sheet with: «Записать ученика», «Регулярные тренировки», and «Свободное время». The AppBar MUST NOT use «Регулярный график» as the sole recurring entry. The FAB MUST remain hidden on «Заявки» and «Доступность» tabs unless product copy explicitly requires otherwise (default: calendar tab only).

#### Scenario: FAB opens create sheet
- **WHEN** the trainer taps the calendar create FAB
- **THEN** the three actions above are shown

#### Scenario: Recurring from create sheet
- **WHEN** the trainer chooses «Регулярные тренировки»
- **THEN** the recurring list/create flow opens inside the authenticated shell

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

### Requirement: Calendar session opens manage actions
When a trainer taps a non-cancelled session event on the calendar, the app SHALL navigate to the session workout page for that occurrence, where mark completed, cancel, mark no-show (when permitted), history, and workout content are available — instead of presenting only a manage sheet as the primary UI.

#### Scenario: Tap booked session
- **WHEN** a trainer taps a booked session on the calendar
- **THEN** the app opens the session workout page with status actions and workout content

### Requirement: Cancelled sessions do not block calendar availability display
The calendar event map SHALL omit sessions with status `cancelled` so that a released open slot at the same interval can appear as availability.

#### Scenario: Cancelled session omitted
- **WHEN** calendar events are mapped and a session is `cancelled`
- **THEN** that session is not shown as a calendar event

### Requirement: Calendar event cards use FyCard
Trainer calendar event cards SHALL render using `FyCard` (or a thin wrapper over it) rather than a raw Material `Card`, preserving existing event type accents, tap targets, and Russian labels.

#### Scenario: Free or booked event is shown
- **WHEN** the day/week/month projection shows an availability, session, or request card
- **THEN** the card chrome comes from the shared Fitness Yoda card primitive

### Requirement: Calendar action sheets use shared bottom sheet shell
Create-actions, open-slot actions, and free-time sheets opened from the calendar SHALL use `showFyBottomSheet` (shared helper). Behavior of actions (book student, recurring, free time, delete) MUST remain unchanged.

#### Scenario: Trainer opens open-slot actions
- **WHEN** the trainer taps a free-time availability card and the slot actions sheet appears
- **THEN** the sheet uses the shared bottom-sheet shell and still offers book / recurring / delete as before

### Requirement: Calendar chips use FyChip
Mode, type, or weekday chips used inside calendar-related pickers that follow the shared selectable-chip pattern SHALL use `FyChip` after migration instead of private `_ModeChip` / `_TypeChip` duplicates.

#### Scenario: Trainer picks weekdays for a related flow from calendar
- **WHEN** a weekday multi-picker rendered from schedule UI is shown
- **THEN** selected and unselected chips use `FyChip` visuals

### Requirement: Day timeline scales hour rows so mid-hour bookings stay clock-aligned
The day hour timeline SHALL size hour rows using a day-wide minutes-to-pixels scale such that an event card for a session whose start is not on `:00` (for example 12:10–13:10) remains vertically placed by clock time and does not visually occupy the next hour’s label band as if the previous hour’s fixed slot were too short. Empty working hours without events MUST remain visible. When all visible events on the day are hour-aligned and long enough for the baseline hour height, the timeline MUST keep the baseline hour height (no unnecessary zoom).

#### Scenario: Mid-hour sixty-minute session
- **WHEN** the selected day shows a single session from 12:10 to 13:10 among working hours that include 12 and 13
- **THEN** the card’s top sits below the 12:00 row start by the scaled 10-minute offset and the card’s span matches the scaled 60 minutes so the 13:00 hour label is not buried inside an undersized previous row

#### Scenario: Hour-aligned session keeps baseline scale
- **WHEN** the selected day only has sessions that start and end on whole hours with duration at least one hour
- **THEN** each displayed hour row uses the baseline hour height

#### Scenario: Empty working hour stays on the grid
- **WHEN** a working hour has no bookings
- **THEN** that hour still appears on the timeline at the same day scale as other hours

### Requirement: Day timeline may show half-hour labels only where needed
The day timeline MAY render a secondary `HH:30` label on the left time axis only for hours that contain an active event whose start or end minute is 30. Hours without such events MUST NOT show a half-hour label.

#### Scenario: Half-hour booking adds :30 tick
- **WHEN** the selected day has a session 12:30–13:30
- **THEN** the hour row for 12 (and/or 13 as implemented) shows a muted `12:30` (respectively `13:30`) under the whole-hour label

#### Scenario: Whole-hour-only day has no :30 ticks
- **WHEN** all events on the day start and end on whole hours
- **THEN** the left axis shows only `HH:00` labels

### Requirement: Day mode exposes previous and next day controls
In «День» mode the calendar toolbar SHALL show previous/next chevrons that move the selected local date by one calendar day (including across week boundaries), in addition to the seven-day date strip. The controls MUST use the same keys/behavior pattern as week/month period navigation (`calendar-prev` / `calendar-next`).

#### Scenario: Trainer advances past the strip week
- **WHEN** the trainer is in «День» mode on Sunday of the visible strip and activates next
- **THEN** the selected date becomes the following Monday and the date strip updates to that week's seven days

#### Scenario: Trainer moves to previous day
- **WHEN** the trainer activates previous in «День» mode
- **THEN** the selected local date moves back by one calendar day and the timeline reloads for that date

### Requirement: Day timeline keeps events aligned to their clock hours
The day hour timeline SHALL expand its visible hour range to include every event's start and end on the selected day. An event whose start is outside the trainer's typical availability windows (for example 21:00 when generated slots end at 19:00) MUST still render at the vertical offset that matches its start hour relative to the hour labels, without jumping across empty hour columns or appearing in a blank gap below the labelled grid.

#### Scenario: Evening session outside default slot span
- **WHEN** the selected day has a training at 21:00 and availability windows only covered earlier hours
- **THEN** the timeline shows an hour label covering 21:00 and places the event card at that hour's offset

#### Scenario: Overlapping events stay readable without clock misalignment
- **WHEN** two events overlap in time on the day timeline
- **THEN** cards remain readable and each card's vertical position still reflects its start time within the expanded hour range

### Requirement: Booked calendar events show attached workout titles
The trainer calendar SHALL display up to two workout titles on a booked session (comma-separated) when workouts are attached, and a Russian affordance to open the series program when the session belongs to a recurring booking that has or can have a program. Tapping the event still opens the session page.

#### Scenario: Strength on Monday cell
- **WHEN** a Monday booked session has workout «Силовая»
- **THEN** the calendar event shows «Силовая» in addition to the student name

#### Scenario: Two titles
- **WHEN** the session has «Ноги» and «Кор»
- **THEN** the event shows both names

### Requirement: Day mode animates selected-date changes
In trainer calendar **day** mode, when the selected local date changes (via date strip, period controls, or equivalent), the day body content SHALL transition with a short AnimatedSwitcher-style fade/slide. Changing calendar mode (day/week/month) MUST NOT be required to use the same animation. Reduced-motion settings MUST suppress or minimize the transition. Event projection and tap targets MUST remain unchanged.

#### Scenario: Trainer picks another day
- **WHEN** the trainer selects a different local date while remaining in day mode
- **THEN** the day timeline/body updates with a brief fade and/or slide and still shows the correct events for that date

#### Scenario: Mode change is not forced through day animation
- **WHEN** the trainer switches from day to week mode
- **THEN** the calendar still switches modes correctly without requiring the day-date animation contract
