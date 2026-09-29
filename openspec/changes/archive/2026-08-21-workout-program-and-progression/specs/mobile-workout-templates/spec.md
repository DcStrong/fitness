## ADDED Requirements

### Requirement: Trainer can edit working weights for a whole workout in one table
The mobile template and student-copy editors SHALL show a Russian «Нагрузки» table listing `weight_reps` exercises with a single weight field per exercise that applies to all sets of that exercise. The trainer MUST be able to change those weights without expanding each exercise into per-set accordions. Saving MUST persist via plan loads or equivalent nested update without changing the parent catalog exercise.

#### Scenario: Set all strength loads on one screen
- **WHEN** a trainer opens «Силовая» and sets bench 80 kg and row 60 kg in «Нагрузки» and saves
- **THEN** the workout stores those weights on the corresponding sets and the exercise library entries are unchanged

#### Scenario: Bodyweight rows omitted from loads table
- **WHEN** the workout includes pull-ups as `bodyweight_reps`
- **THEN** pull-ups do not appear as a weight field in «Нагрузки»
