## ADDED Requirements

### Requirement: Booked calendar events show attached workout titles
The trainer calendar SHALL display up to two workout titles on a booked session (comma-separated) when workouts are attached, and a Russian affordance to open the series program when the session belongs to a recurring booking that has or can have a program. Tapping the event still opens the session page.

#### Scenario: Strength on Monday cell
- **WHEN** a Monday booked session has workout «Силовая»
- **THEN** the calendar event shows «Силовая» in addition to the student name

#### Scenario: Two titles
- **WHEN** the session has «Ноги» and «Кор»
- **THEN** the event shows both names
