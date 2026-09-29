## MODIFIED Requirements

### Requirement: User can complete cancel or mark no_show from sessions UI
The mobile app SHALL show Russian actions on a `booked` session according to role: coach — complete / cancel / no-show; student — cancel. Primary entry SHALL be the session workout page. Complete SHALL be the single primary button on that page when the coach may complete. Cancel and no-show SHALL remain available from the same page as quiet text or ⋯ actions with the existing confirmation dialogs; they MUST NOT be presented as a second and third full-width button of similar weight to «Проведена». After success the page and calendar/list refresh and show the new status.

#### Scenario: Coach completes from UI
- **WHEN** a coach confirms «Проведена» on a booked session from the session page
- **THEN** the app calls complete API and shows status `completed`

#### Scenario: Student cancels from UI
- **WHEN** a student confirms «Отменить» on a booked session
- **THEN** the app calls cancel API and shows status `cancelled`

#### Scenario: Coach no-show stays available without matching complete
- **WHEN** a coach opens a booked session they may mark no-show
- **THEN** they can still confirm no-show from a quiet control or ⋯, not from a second primary button
