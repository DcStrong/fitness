## ADDED Requirements

### Requirement: Home loads the current local day's sessions
The mobile Home dashboard SHALL request only the authenticated user's sessions that overlap the current calendar day in the device timezone, using an inclusive local start and exclusive next-day boundary converted to UTC for the existing sessions API.

#### Scenario: Trainer opens Home during a normal day
- **WHEN** an authenticated trainer opens Home
- **THEN** the app requests sessions with `from` equal to local midnight and `to` equal to the next local midnight, both represented as UTC ISO-8601 values

#### Scenario: Session overlaps midnight
- **WHEN** a session starts before local midnight and ends after it
- **THEN** the session is included in the current day's dashboard

#### Scenario: Local day changes while Home remains open
- **WHEN** the device crosses into the next local calendar day while Home is active
- **THEN** the dashboard reloads sessions using the new day's boundaries

### Requirement: Home prioritizes current and upcoming sessions
The mobile Home dashboard SHALL keep booked sessions whose end time is after the current time visible in the main schedule, ordered by start time.

#### Scenario: Session is currently in progress
- **WHEN** a booked session has started and has not ended
- **THEN** it remains in the main schedule and is labelled as currently in progress

#### Scenario: Session starts later today
- **WHEN** a booked session starts after the current time
- **THEN** it appears in the main schedule as planned in ascending start-time order

#### Scenario: No active or upcoming sessions remain
- **WHEN** today's loaded sessions contain no booked session ending after the current time
- **THEN** the main schedule shows a concise message that no more trainings are planned today

### Requirement: Earlier and terminal sessions are collapsed into daily history
The mobile Home dashboard SHALL place sessions whose end time has passed or whose lifecycle status is `completed`, `cancelled`, or `no_show` into an inline History section that is collapsed by default.

#### Scenario: Home opens with historical entries
- **WHEN** at least one loaded session belongs to daily history
- **THEN** Home shows a collapsed History header with the number of entries and does not render the history rows until expanded

#### Scenario: User expands daily history
- **WHEN** the user activates the collapsed History header
- **THEN** all history rows for the current day are displayed inline in chronological order

#### Scenario: User collapses daily history
- **WHEN** the expanded History header is activated again
- **THEN** the history rows are hidden while the entry count remains visible

#### Scenario: Booked session ended without lifecycle update
- **WHEN** a session still has `booked` status but its end time has passed
- **THEN** it appears in History with a status indicating that the result still requires marking

#### Scenario: Terminal session is scheduled later
- **WHEN** a session has `completed`, `cancelled`, or `no_show` status even though its scheduled end is later than the current time
- **THEN** it appears in History rather than among upcoming trainings

### Requirement: Session rows represent scheduled trainings
Each booked slot represented by a Session SHALL be treated as a training between its trainer and student. Each Home schedule row SHALL show its local time interval, counterpart email or id, and localized status without requiring a separate training title.

#### Scenario: Counterpart email is available
- **WHEN** a loaded session contains the other participant's email
- **THEN** the row shows that email alongside its time and status

#### Scenario: Counterpart email is unavailable
- **WHEN** the other participant's email is absent
- **THEN** the row shows the other participant's id without inventing a display name

#### Scenario: Scheduled session has no separate title
- **WHEN** a Session is rendered in the daily schedule
- **THEN** the slot itself is presented as the training and the UI does not require or invent an additional training name

#### Scenario: User opens a session
- **WHEN** the user activates a Home schedule row
- **THEN** the app navigates to the existing sessions destination where lifecycle, payment, and history actions remain available

### Requirement: Trainer has quick invitation access
The Home header SHALL show an accessible QR-code action to authenticated trainers and SHALL use the existing invitation route rather than implementing invitation creation on Home.

#### Scenario: Trainer activates QR action
- **WHEN** an authenticated trainer taps the QR-code icon labelled «Пригласить ученика»
- **THEN** the app navigates to `/invite`

#### Scenario: Student opens Home directly
- **WHEN** an authenticated student reaches Home through a direct route
- **THEN** the trainer-only QR invitation action is not displayed

### Requirement: Key feature cards follow the schedule
The Home dashboard SHALL place compact, fully tappable feature cards after the daily schedule and SHALL derive their destinations from the authenticated user's roles and permissions.

#### Scenario: Trainer has finance permission
- **WHEN** a trainer with `finance:read_own` views Home
- **THEN** cards provide access to schedule, students/invitations, plans, and finance

#### Scenario: Trainer lacks finance permission
- **WHEN** a trainer without `finance:read_own` views Home
- **THEN** no finance card is displayed

#### Scenario: Student opens Home directly
- **WHEN** a student views Home
- **THEN** cards provide access to own sessions, booking, trainers, and visible plans without exposing trainer-only destinations

#### Scenario: User activates a feature card
- **WHEN** the user taps anywhere on a feature card
- **THEN** the router opens that card's existing protected destination

### Requirement: Home exposes loading, failure, empty, and refresh behavior
The Home dashboard SHALL communicate session loading and failure without hiding feature navigation, SHALL provide retry after failure, and SHALL support manual refresh of the current day's data.

#### Scenario: Sessions are loading
- **WHEN** the current day's request is in progress
- **THEN** the schedule area shows a loading treatment while the Home shell remains usable

#### Scenario: Sessions request fails
- **WHEN** the current day's request fails
- **THEN** the schedule area shows a Russian error message and a retry action without claiming that the day is empty

#### Scenario: Current day has no sessions
- **WHEN** the request succeeds with an empty list
- **THEN** the schedule area shows a concise empty state and the feature cards remain available below it

#### Scenario: User refreshes Home
- **WHEN** the user performs the dashboard's manual refresh gesture or action
- **THEN** the app reloads sessions using freshly calculated current-day boundaries

### Requirement: Home preserves the Fitness Yoda visual language
The Home dashboard SHALL use the existing Fitness Yoda theme tokens and reusable soft-card patterns, treating the supplied sketch as an information-layout reference rather than a replacement visual style.

#### Scenario: Dashboard is rendered on a standard device
- **WHEN** populated Home content is displayed
- **THEN** it uses the existing canvas, primary/mint accents, typography, radii, spacing, and soft surfaces

#### Scenario: Dashboard is rendered on a narrow device
- **WHEN** the available width cannot fit multiple feature cards without clipping
- **THEN** cards reflow without horizontal overflow and all schedule content remains vertically scrollable
