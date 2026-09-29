## ADDED Requirements

### Requirement: Recurring detail secondary actions use FySecondaryButton
Recurring booking detail (and create where applicable) non-primary actions SHALL use `FySecondaryButton` instead of raw `OutlinedButton`, while primary CTAs remain on the existing primary button primitives.

#### Scenario: Trainer sees skip or secondary conflict action
- **WHEN** recurring detail shows a non-primary action button
- **THEN** that control is a `FySecondaryButton` with Russian label unchanged

### Requirement: Recurring forms use shared chips and sheets
Weekday / mode selection on recurring create and any modal sheets in the recurring flow that match calendar patterns SHALL use `FyChip` and `showFyBottomSheet` respectively after migration.

#### Scenario: Trainer selects weekdays on create
- **WHEN** the trainer opens «Новые регулярные тренировки» and toggles weekdays
- **THEN** weekday chips are `FyChip`-based and selection still drives create payload weekdays
