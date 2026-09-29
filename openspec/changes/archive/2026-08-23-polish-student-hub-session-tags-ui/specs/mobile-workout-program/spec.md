## MODIFIED Requirements

### Requirement: Program is reachable from series, calendar, and student profile
The mobile app SHALL open the program screen from recurring series detail («Программа»), from a booked calendar event that belongs to that series, and from the student profile/hub when a series exists — including the hub «Программа» text link beside «На этой неделе» and the Программа cell of the compact action grid. Copy MUST be Russian. Opening program from the session page, if offered, MUST be a text link or overflow item, not a competing CTA.

#### Scenario: Open from series detail
- **WHEN** a trainer taps «Программа» on an active series
- **THEN** the program screen loads for that recurring booking

#### Scenario: Open from calendar
- **WHEN** a trainer opens program from a booked Monday session of the series
- **THEN** the same program screen opens with Monday's workouts visible

#### Scenario: Open from student hub week or grid
- **WHEN** a trainer activates «Программа» on a student hub that has a series
- **THEN** the same program screen opens for that recurring booking
