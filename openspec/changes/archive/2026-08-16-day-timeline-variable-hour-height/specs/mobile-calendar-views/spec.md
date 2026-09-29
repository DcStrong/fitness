## ADDED Requirements

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
