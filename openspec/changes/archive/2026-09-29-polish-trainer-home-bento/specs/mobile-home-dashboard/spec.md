## ADDED Requirements

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
The trainer Home dashboard SHALL show a horizontal row of compact mint-soft stat chips near the top of the scroll content. The row MUST include a chip for today's session count and, when pending request data is available, a chip for pending booking requests with navigation to the trainer inbox. A third chip MUST summarize the loaded week's booked session count or an equivalent week-scope metric derived without new backend endpoints.

#### Scenario: Trainer has pending requests
- **WHEN** pending count loaded successfully and is greater than zero
- **THEN** a «Заявки» chip shows the count and navigates to the inbox on activation

#### Scenario: Pending count unavailable
- **WHEN** the pending-count request fails
- **THEN** Home does not show a misleading zero «Заявки» chip

### Requirement: Trainer shortcuts use an asymmetric bento layout
The trainer «Всё необходимое» section SHALL use an asymmetric bento grid instead of a single-column stack of equal feature cards. The layout MUST include: a tall primary tile for «Расписание», stacked tiles for «Ученики» and «Планирование», and a full-width tile for «Регулярные тренировки». Finance access, when permitted, MUST remain available without breaking the bento rhythm. All tiles MUST remain fully tappable and route to the same protected destinations as before.

#### Scenario: Trainer with finance permission
- **WHEN** a trainer with `finance:read_own` views Home
- **THEN** finance remains reachable and the bento layout still presents «Расписание», «Ученики», «Планирование», and «Регулярные тренировки»

#### Scenario: Trainer activates a bento tile
- **WHEN** the trainer taps the «Ученики» tile
- **THEN** the router opens `/session-packages` as today

## MODIFIED Requirements

### Requirement: Key feature cards follow the schedule
The Home dashboard SHALL place role-aware navigation shortcuts after the daily schedule (and after any week mini-calendar or stat chips for trainers). Trainer shortcuts MUST use the asymmetric bento layout. Student shortcuts MUST use a two-column feature grid on standard phone widths without horizontal overflow. Cards and tiles MUST remain fully tappable and derive destinations from roles and permissions unchanged.

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

### Requirement: Home preserves the Fitness Yoda visual language
The Home dashboard SHALL use the existing Fitness Yoda theme tokens and reusable soft-card patterns. Trainer bento tiles SHOULD use the established action fill and mint accent treatments documented in the design pack. Layout references such as `mock-home-c-asymmetric-bento.png` define information hierarchy only, not pixel-perfect dimensions.

#### Scenario: Dashboard is rendered on a standard device
- **WHEN** populated Home content is displayed
- **THEN** it uses the existing canvas, primary/mint accents, typography, radii, spacing, and soft surfaces

#### Scenario: Dashboard is rendered on a narrow device
- **WHEN** the available width is phone-sized
- **THEN** student feature cards use two columns, trainer bento tiles reflow without horizontal overflow, and all content remains vertically scrollable
