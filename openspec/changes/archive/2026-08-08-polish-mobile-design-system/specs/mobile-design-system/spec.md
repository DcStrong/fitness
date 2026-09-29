## ADDED Requirements

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
