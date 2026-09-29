# mobile-home-dashboard Specification

## Purpose
Define the role-aware mobile Home dashboard, including the current day's schedule, inline history, quick invitation access, feature navigation, and operational states.
## Requirements
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

### Requirement: Trainer has quick invitation access
The Home header SHALL show an accessible QR-code action to authenticated trainers and SHALL use the existing invitation route rather than implementing invitation creation on Home.

#### Scenario: Trainer activates QR action
- **WHEN** an authenticated trainer taps the QR-code icon labelled «Пригласить ученика»
- **THEN** the app navigates to `/invite`

#### Scenario: Student opens Home directly
- **WHEN** an authenticated student reaches Home through a direct route
- **THEN** the trainer-only QR invitation action is not displayed

### Requirement: Key feature cards follow the schedule
The Home dashboard SHALL place role-aware navigation shortcuts after the daily schedule (and after any week mini-calendar or stat chips for trainers). Trainer shortcuts MUST use the asymmetric bento layout. Student shortcuts MUST use a two-column feature grid on standard phone widths without horizontal overflow. Cards and tiles MUST remain fully tappable and derive destinations from roles and permissions unchanged. The student «Тренировки» / «Планы» card SHALL open upcoming sessions plus assigned copies rather than only legacy visible text plans.

#### Scenario: Trainer has finance permission
- **WHEN** a trainer with `finance:read_own` views Home
- **THEN** finance remains accessible and schedule/students/plans/recurring shortcuts appear in the bento layout

#### Scenario: Trainer lacks finance permission
- **WHEN** a trainer without `finance:read_own` views Home
- **THEN** no finance shortcut is displayed

#### Scenario: Student opens Home directly
- **WHEN** a student views Home
- **THEN** feature shortcuts appear in a two-column grid providing access to own sessions, booking, trainers, and assigned workouts without trainer-only destinations

#### Scenario: User activates a feature shortcut
- **WHEN** the user taps anywhere on a shortcut tile or card
- **THEN** the router opens that shortcut's existing protected destination

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
The Home dashboard SHALL use the existing Fitness Yoda theme tokens and reusable soft-card patterns. Trainer stat cards and bento tiles MUST use a white or canvas soft surface with mint as an accent, not a solid mint fill across the card. Layout references such as `mock-home-c-asymmetric-bento.png` define information hierarchy only, not pixel-perfect dimensions.

#### Scenario: Dashboard is rendered on a standard device
- **WHEN** populated trainer Home content is displayed
- **THEN** stat cards and bento tiles use soft light surfaces and mint accents rather than a solid mint card fill

#### Scenario: Dashboard is rendered on a narrow device
- **WHEN** the available width is phone-sized
- **THEN** student feature cards use two columns, trainer bento tiles reflow without horizontal overflow, and all content remains vertically scrollable

### Requirement: Trainer Home exposes pending booking request count
The mobile Home dashboard SHALL load the authenticated trainer's non-expired pending BookingRequest count and surface it through the stat-chip row and/or a compact actionable treatment, but MUST NOT duplicate the same urgent count in both a large banner and an identical chip when the chip is shown. Student Home MUST NOT expose trainer inbox UI.

#### Scenario: Trainer has pending requests
- **WHEN** the trainer Home successfully loads a pending count greater than zero
- **THEN** the count is visible through the chip or compact action leading to the request inbox

#### Scenario: Trainer has no pending requests
- **WHEN** the pending count is zero
- **THEN** Home does not show a misleading urgent badge

#### Scenario: Count request fails
- **WHEN** the pending-count API fails while the daily Session request succeeds
- **THEN** the daily schedule and feature navigation remain usable and Home does not claim a zero count

#### Scenario: Student opens Home
- **WHEN** an authenticated student reaches Home
- **THEN** no trainer request count or inbox destination is shown

### Requirement: Home pending count refreshes after request decisions
The mobile app SHALL refresh the trainer Home pending count after returning from an inbox mutation or performing a manual Home refresh.

#### Scenario: Trainer accepts from inbox
- **WHEN** the trainer resolves a pending request and returns to Home
- **THEN** Home obtains an updated pending count rather than retaining the stale badge value

### Requirement: Upcoming trainings section can collapse
The mobile Home dashboard SHALL present the main upcoming/current schedule under a Russian «Предстоящие тренировки» (or equivalent) header that can expand and collapse like daily History. The upcoming section MUST default to expanded. Collapsing MUST hide the upcoming session rows while keeping the header and count visible; expanding MUST show the rows again. History collapse behavior remains unchanged.

#### Scenario: Home opens with upcoming expanded
- **WHEN** Home loads with at least one upcoming or in-progress training
- **THEN** the upcoming header shows the count and the session rows are visible by default

#### Scenario: User collapses upcoming
- **WHEN** the user activates the upcoming header while it is expanded
- **THEN** the upcoming rows are hidden while the header and count remain visible

#### Scenario: User expands upcoming again
- **WHEN** the user activates the collapsed upcoming header
- **THEN** the upcoming rows are displayed again in chronological order

### Requirement: Trainer Home shows a week mini-calendar with workout hints
The trainer Home dashboard SHALL display a horizontal mini-calendar for the current local calendar week (Monday through Sunday) below the date header and above the daily schedule list. Each day cell MUST show the weekday label and day number using Fitness Yoda calendar styling consistent with the schedule date strip. When at least one booked session exists on that day within the loaded week range, the cell MUST show a truncated workout or counterpart hint derived from existing session payload; empty days MUST NOT invent labels. Tapping a day MUST provide a schedule-related navigation affordance (at minimum opening the primary schedule destination).

#### Scenario: Trainer opens Home mid-week
- **WHEN** an authenticated trainer opens Home and the week has sessions on Monday and Wednesday
- **THEN** the mini-calendar shows seven day cells and Monday/Wednesday cells include session hints from loaded data

#### Scenario: Day without sessions
- **WHEN** a weekday in the current week has no booked sessions in the loaded range
- **THEN** the cell remains tappable but does not show a fabricated workout title

#### Scenario: User taps a week day cell
- **WHEN** the trainer taps any day in the mini-calendar strip
- **THEN** the app opens the schedule experience rather than leaving the user on a dead control

### Requirement: Trainer Home exposes compact stat chips for daily scan
The trainer Home dashboard SHALL show a row of stat cards near the top of the scroll content. Each card MUST show an icon, a short Russian label, and a numeric value. The row MUST include today's session count and, when pending request data loaded successfully, the pending booking request count with navigation to the trainer inbox when the count is greater than zero. A third card MUST show the loaded week's booked session count labeled «На неделе», unless a free-slot count is already present in loaded Home state without a new backend request, in which case that card MUST be labeled «Свободно» and show that count.

#### Scenario: Trainer has pending requests
- **WHEN** pending count loaded successfully and is greater than zero
- **THEN** a «Заявки» card shows an icon, the label, and the count, and navigates to the inbox on activation

#### Scenario: Pending count unavailable
- **WHEN** the pending-count request fails
- **THEN** Home does not show a misleading zero «Заявки» card

#### Scenario: Free slots are not in loaded state
- **WHEN** Home has a week session count and no free-slot count in loaded state
- **THEN** the third card is labeled «На неделе» and shows the booked week count

### Requirement: Trainer shortcuts use an asymmetric bento layout
The trainer «Всё необходимое» section SHALL use an asymmetric bento grid instead of a single-column stack of equal feature cards. The layout MUST include: a tall primary tile for «Расписание», stacked tiles for «Ученики» and «Планирование», and a full-width tile for «Регулярные тренировки». The «Расписание» tile MUST include a seven-day mini chart of booked session counts for the already loaded week. The «Расписание» and «Регулярные тренировки» tiles MUST show a «Перейти» action that routes to the same destination as the tile. Finance access, when permitted, MUST remain available without breaking the bento rhythm. All tiles MUST remain fully tappable and route to the same protected destinations as before. Tiles MUST use a light soft surface.

#### Scenario: Trainer with finance permission
- **WHEN** a trainer with `finance:read_own` views Home
- **THEN** finance remains reachable and the bento layout still presents «Расписание», «Ученики», «Планирование», and «Регулярные тренировки»

#### Scenario: Trainer activates a bento tile
- **WHEN** the trainer taps the «Ученики» tile
- **THEN** the router opens `/session-packages` as today

#### Scenario: Schedule tile shows the week chart
- **WHEN** the loaded week has booked sessions on some days
- **THEN** the «Расписание» tile shows a seven-day chart derived from those counts and a «Перейти» action to the schedule destination

### Requirement: Trainer Home header shows a date chip
The trainer Home header SHALL show a compact date chip for the current local calendar day, using a Russian label that identifies today (for example «Сегодня» plus the date). The chip MUST use existing theme tokens and MUST NOT require a new API call.

#### Scenario: Trainer opens Home
- **WHEN** an authenticated trainer opens Home
- **THEN** the header includes a date chip for the current local day

### Requirement: Trainer today list is a timeline with counterpart avatars
The trainer daily schedule on Home SHALL present session rows as a vertical timeline. Each row MUST show a circular counterpart avatar: a network image when an image URL is already present on the loaded session model, otherwise initials derived from the counterpart display name. The row MUST still show time and the training identity already available on the session.

#### Scenario: Session has no image URL
- **WHEN** a trainer views a today session whose counterpart has a name and no image URL
- **THEN** the timeline row shows initials from that name

#### Scenario: Today has no sessions
- **WHEN** the current-day request succeeds with an empty list
- **THEN** the schedule area shows the existing concise empty state

