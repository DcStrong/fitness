## ADDED Requirements

### Requirement: Calendar event cards use FyCard
Trainer calendar event cards SHALL render using `FyCard` (or a thin wrapper over it) rather than a raw Material `Card`, preserving existing event type accents, tap targets, and Russian labels.

#### Scenario: Free or booked event is shown
- **WHEN** the day/week/month projection shows an availability, session, or request card
- **THEN** the card chrome comes from the shared Fitness Yoda card primitive

### Requirement: Calendar action sheets use shared bottom sheet shell
Create-actions, open-slot actions, and free-time sheets opened from the calendar SHALL use `showFyBottomSheet` (shared helper). Behavior of actions (book student, recurring, free time, delete) MUST remain unchanged.

#### Scenario: Trainer opens open-slot actions
- **WHEN** the trainer taps a free-time availability card and the slot actions sheet appears
- **THEN** the sheet uses the shared bottom-sheet shell and still offers book / recurring / delete as before

### Requirement: Calendar chips use FyChip
Mode, type, or weekday chips used inside calendar-related pickers that follow the shared selectable-chip pattern SHALL use `FyChip` after migration instead of private `_ModeChip` / `_TypeChip` duplicates.

#### Scenario: Trainer picks weekdays for a related flow from calendar
- **WHEN** a weekday multi-picker rendered from schedule UI is shown
- **THEN** selected and unselected chips use `FyChip` visuals
