## ADDED Requirements

### Requirement: Authenticated shell uses the shared custom top bar
Authenticated destinations presented inside the app shell SHALL use the shared Fitness Yoda top bar (title and optional subtitle) instead of an unstyled default Material AppBar appearance, except where a screen deliberately opts into a documented full-bleed or modal presentation. Nested authenticated routes that show a leading back control MUST still use the shared top bar styling.

#### Scenario: Trainer opens Home
- **WHEN** an authenticated trainer lands on Home inside the shell
- **THEN** the screen chrome uses the shared top bar title treatment rather than an unrelated default Material AppBar look

#### Scenario: Nested authenticated route
- **WHEN** the user opens a nested authenticated route that shows a back affordance
- **THEN** the top chrome remains visually consistent with the shared top bar (including leading back) and does not introduce a notification bell

### Requirement: Shell tab changes use fade and slide motion
When the user switches among primary shell tabs (IndexedStack / StatefulShell branches), the shell SHALL animate the incoming branch with a short fade and slight slide. Reduced-motion settings MUST suppress or minimize the transition.

#### Scenario: User switches bottom tab
- **WHEN** an authenticated user selects a different primary bottom-navigation destination
- **THEN** the newly visible branch appears with a brief fade and slide rather than an instantaneous hard cut

#### Scenario: Tab switch with reduced motion
- **WHEN** reduce-motion is enabled and the user switches tabs
- **THEN** the destination still changes without a long decorative animation
