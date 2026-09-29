## MODIFIED Requirements

### Requirement: User can complete cancel or mark no_show from sessions UI
The mobile app SHALL show Russian actions on a `booked` session according to role: coach — complete / cancel / no-show; student — cancel. Primary entry SHALL be the session workout page. After success the page and calendar/list refresh and show the new status.

#### Scenario: Coach completes from UI
- **WHEN** a coach confirms «Проведена» on a booked session from the session page
- **THEN** the app calls complete API and shows status `completed`

#### Scenario: Student cancels from UI
- **WHEN** a student confirms «Отменить» on a booked session
- **THEN** the app calls cancel API and shows status `cancelled`
