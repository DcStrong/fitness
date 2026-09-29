## MODIFIED Requirements

### Requirement: Session rows represent scheduled trainings
Each booked slot represented by a Session SHALL be treated as a training between its trainer and student. Each Home schedule row SHALL show its local time interval, counterpart email or id, localized status, and the attached workout title when `studentPlanId` is present. A missing title MUST NOT be invented.

#### Scenario: Counterpart email is available
- **WHEN** a loaded session contains the other participant's email
- **THEN** the row shows that email alongside its time and status

#### Scenario: Counterpart email is unavailable
- **WHEN** the other participant's email is absent
- **THEN** the row shows the other participant's id without inventing a display name

#### Scenario: Scheduled session has an attached workout title
- **WHEN** a Session rendered in the daily schedule has an attached student copy
- **THEN** the row shows that copy's title in addition to time and counterpart

#### Scenario: Scheduled session has no workout attached
- **WHEN** a Session has no attached plan
- **THEN** the UI does not invent a training name beyond the time slot

#### Scenario: User opens a session
- **WHEN** the user activates a Home schedule row
- **THEN** the app navigates to the session workout page

### Requirement: Key feature cards follow the schedule
The Home dashboard SHALL place compact, fully tappable feature cards after the daily schedule and SHALL derive their destinations from the authenticated user's roles and permissions. The student «Тренировки» / «Планы» card SHALL open upcoming sessions plus assigned copies rather than only legacy visible text plans.

#### Scenario: Trainer has finance permission
- **WHEN** a trainer with `finance:read_own` views Home
- **THEN** cards provide access to schedule, students/invitations, plans, and finance

#### Scenario: Trainer lacks finance permission
- **WHEN** a trainer without `finance:read_own` views Home
- **THEN** no finance card is displayed

#### Scenario: Student opens Home directly
- **WHEN** a student views Home
- **THEN** cards provide access to own sessions, booking, trainers, and assigned/upcoming workouts without exposing trainer-only destinations

#### Scenario: User activates a feature card
- **WHEN** the user taps anywhere on a feature card
- **THEN** the router opens that card's existing protected destination
