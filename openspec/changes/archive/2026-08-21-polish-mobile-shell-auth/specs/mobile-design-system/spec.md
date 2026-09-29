## ADDED Requirements

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
