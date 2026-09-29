## ADDED Requirements

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
