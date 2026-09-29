## ADDED Requirements

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

## MODIFIED Requirements

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
