# mobile-design-system Specification

## Purpose
Define the shared Fitness Yoda visual language, reusable Flutter presentation components, and incremental verification expectations for mobile auth, home, and schedule surfaces.

## Requirements

### Requirement: Mobile surfaces use Fitness Yoda design tokens
The Flutter application SHALL use `app/design/tokens.md` as the visual source of truth for its light theme, including the documented primary, surface, canvas, text, secondary, mint, radius, spacing, and soft-shadow values.

#### Scenario: Authenticated or unauthenticated screen is rendered
- **WHEN** a user opens a redesigned mobile screen
- **THEN** the screen uses the Fitness Yoda canvas, surface, text, and accent roles instead of unrelated default Material seed values

#### Scenario: Primary action is rendered
- **WHEN** a redesigned screen displays its primary call to action
- **THEN** the action uses the documented deep-green primary color, on-primary content, stadium shape, and target height

### Requirement: Shared controls expose required interaction states
The Flutter application SHALL provide reusable Fitness Yoda presentation components for primary actions, soft cards, and card-style form inputs without moving networking or domain state into those widgets.

#### Scenario: Primary action is loading
- **WHEN** the existing feature state reports that a primary action is in progress
- **THEN** the shared primary button displays a compact progress indicator and prevents duplicate submission

#### Scenario: Primary action is unavailable
- **WHEN** an existing screen disables its primary action
- **THEN** the shared primary button communicates the disabled state and does not invoke its callback

#### Scenario: Form input is invalid
- **WHEN** an existing form validator reports an invalid value
- **THEN** the card-style input presents the validation feedback while preserving the form's controller, focus, and validation behavior

### Requirement: Authentication screens use the shared design language
Login and Register SHALL use the documented canvas, brand/accent heading rhythm, shared input cards, and shared primary action while preserving existing fields, validators, role values, submission events, loading states, errors, and navigation behavior.

#### Scenario: User submits login
- **WHEN** a user enters valid credentials and activates the redesigned Login primary action
- **THEN** the existing authentication submission flow runs unchanged

#### Scenario: User chooses a registration role
- **WHEN** a user selects trainer or student on the redesigned Register screen
- **THEN** the form submits the same supported role value expected by the existing authentication contract

#### Scenario: Authentication route is shown
- **WHEN** Login or Register is displayed
- **THEN** authenticated bottom navigation is not displayed on that route

### Requirement: Home and schedule surfaces use reusable soft cards
Home, relationship summaries, coach slots, student booking, and session lists SHALL present their existing data and actions using the reusable card, spacing, heading, and primary-action patterns defined by `app/design/**`.

#### Scenario: Home has available actions
- **WHEN** an authenticated user opens Home
- **THEN** the user sees role-appropriate quick actions rendered as Fitness Yoda cards without losing access to existing destinations

#### Scenario: Schedule data is populated
- **WHEN** slots, bookings, sessions, or relationships are available
- **THEN** each existing entity and action remains accessible in the redesigned card-based presentation

#### Scenario: Schedule data is empty
- **WHEN** a redesigned list has no entities to display
- **THEN** the screen displays a concise empty-state treatment using the documented soft mint information style

### Requirement: Design rollout is verified incrementally
The redesign SHALL be delivered in the six-stage order defined by `app/design/prompts/00-readme.md`, and each stage SHALL pass Flutter static analysis and visual inspection on a simulator before it is considered complete.

#### Scenario: A design stage is completed
- **WHEN** implementation of one numbered design prompt is finished
- **THEN** analysis is clean for the affected Flutter code and the affected UI has been inspected against that stage's referenced crops

#### Scenario: A design stage has not been verified
- **WHEN** analysis fails or the affected UI has not been inspected
- **THEN** that stage remains incomplete and the next numbered stage does not start

### Requirement: Light theme uses Plus Jakarta Sans
The Flutter light theme SHALL apply **Plus Jakarta Sans** as the primary text theme for redesigned surfaces, consistent with `app/design/tokens.md`. System fallback MAY remain for platforms where the font fails to load, but the configured theme MUST request Plus Jakarta Sans (via `google_fonts` or bundled font assets). Manrope MUST NOT be introduced as a parallel brand font in this change.

#### Scenario: Auth or shell screen renders text
- **WHEN** a user opens Login, Home, or Schedule after the theme update
- **THEN** body and title text use Plus Jakarta Sans (or the documented fallback), not the previous default Material font stack alone

### Requirement: Shared secondary button
The Flutter app SHALL provide a reusable `FySecondaryButton` (outlined stadium) for non-primary actions without embedding networking or domain state in the widget. Loading and disabled states MUST be supported consistently with the primary button patterns.

#### Scenario: Secondary action is shown
- **WHEN** a redesigned screen needs a non-primary action (e.g. skip / cancel-style control on recurring detail)
- **THEN** the screen uses `FySecondaryButton` rather than a raw `OutlinedButton` for that control

#### Scenario: Secondary action is disabled
- **WHEN** the feature state disables the secondary action
- **THEN** the button communicates the disabled state and does not invoke its callback

### Requirement: Shared chip control
The Flutter app SHALL provide a reusable `FyChip` for selectable labels (mode, type, weekday) with clear selected/unselected presentation using Fitness Yoda colors. Feature modules MUST NOT keep parallel private chip widgets for the same pattern once migrated.

#### Scenario: Weekday or mode chip is selected
- **WHEN** the trainer toggles a weekday or mode chip built on `FyChip`
- **THEN** the selected state is visually distinct (mint/primary treatment) and the callback updates feature state only

### Requirement: Shared bottom sheet shell
The Flutter app SHALL expose `showFyBottomSheet` (or equivalent named helper) that applies documented surface, top radius, and safe-area padding for modal sheets. Schedule create/slot/free-time sheets MUST open through this helper.

#### Scenario: Trainer opens create actions
- **WHEN** the trainer opens the calendar create-actions sheet
- **THEN** the sheet is presented via the shared bottom-sheet helper rather than an ad-hoc `showModalBottomSheet` with divergent chrome

### Requirement: Core widgets barrel export
Shared presentation widgets under `lib/core/widgets/` SHALL be re-exported from a single barrel file so feature code can import the design primitives from one path. Introducing `lib/core/design_system/` as a new package path is NOT required for this change.

#### Scenario: Feature imports shared primitives
- **WHEN** a schedule or recurring screen needs `FyCard`, `FyChip`, or `FySecondaryButton`
- **THEN** those widgets are available through the `core/widgets` barrel without copying widget source into the feature folder

### Requirement: Shared top bar presents title and optional subtitle
The Flutter app SHALL provide a reusable top bar presentation component for authenticated surfaces that shows a primary title and MAY show a muted subtitle. The component MUST NOT include a notification bell or unread-badge control in this change. Presentation state MUST remain outside networking/domain Cubits.

#### Scenario: Authenticated screen with subtitle
- **WHEN** an authenticated screen configures the shared top bar with a title and subtitle
- **THEN** both lines are visible using Fitness Yoda text roles and the documented header rhythm

#### Scenario: No notification control
- **WHEN** the shared top bar is shown
- **THEN** it does not present a notification bell or badge action

### Requirement: Primary actions support press-scale motion
Shared primary call-to-action controls SHALL apply a brief press scale feedback of approximately `0.98` while preserving existing loading, disabled, and callback contracts. Motion MUST be skipped or reduced when the platform requests reduced motion.

#### Scenario: User presses primary CTA
- **WHEN** a user presses an enabled shared primary button
- **THEN** the control briefly scales to about 0.98 and still invokes the existing onPressed path when released on the control

#### Scenario: Reduced motion
- **WHEN** accessibility reduce-motion is enabled
- **THEN** press-scale animation is omitted or minimized without blocking the action

### Requirement: Auth hero may use a bundled brand illustration asset
Login and Register MAY display a bundled Fitness Yoda hero illustration asset behind or beside brand chrome, with soft mint decorative shapes (circle and/or wave). Dot-grid décor MUST NOT be introduced. When the asset is present, the hero block SHOULD occupy roughly 40–42% of the viewport height with the keyboard closed, without changing form fields, validators, role values, submission, or navigation contracts.

#### Scenario: Login shows hero asset
- **WHEN** Login is displayed and the hero asset is bundled
- **THEN** the hero region shows the brand illustration with mint décor and the existing email/password/CTA form remains unchanged in behavior

#### Scenario: Auth panel entrance
- **WHEN** Login or Register is first shown on a route push
- **THEN** the white auth panel uses a short fade and/or slide entrance without delaying form interactivity after the animation completes
