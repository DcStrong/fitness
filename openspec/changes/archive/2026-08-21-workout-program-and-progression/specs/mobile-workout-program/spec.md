## ADDED Requirements

### Requirement: Trainer edits a student's series program on one screen
The mobile app SHALL provide a Russian trainer screen for a RecurringBooking program: header with student and series pattern, horizon control, a section per series weekday with ordered workout cards, add-from-own-templates, a progression block for unique `weight_reps` exercises (current kg and delta over the horizon), a date preview of interpolated weights, and a single save action that upserts and applies. The screen MUST use Bloc/Cubit only. The trainer MUST NOT be required to open each future session to set the same weekly split.

#### Scenario: Assign strength Mon/Sat and legs Thursday
- **WHEN** a trainer puts «Силовая» on Monday and Saturday, «Ноги» on Thursday, sets bench +5 kg over 2 weeks, and saves
- **THEN** the app stores the program and upcoming matching sessions show those workouts with interpolated bench weights

#### Scenario: Empty weekday blocked
- **WHEN** the trainer saves with a weekday that has zero workouts
- **THEN** the app does not submit and explains that each included day needs a workout

### Requirement: Trainer can add several workouts to one weekday
The mobile app SHALL allow more than one template card on the same weekday and persist their order as multiple session workouts for that day.

#### Scenario: Two cards on Thursday
- **WHEN** the trainer adds «Ноги» and «Кор» under Thursday and saves
- **THEN** Thursday sessions list both workouts in that order

### Requirement: Trainer sets loads for a workout without opening each exercise editor
On the program screen each workout card SHALL expose a compact loads table (exercise name + weight) for `weight_reps` items. Editing a weight MUST update the student copy start load for that exercise, not the catalog exercise and not the parent template.

#### Scenario: Change bench from the workout card
- **WHEN** the trainer sets bench to 80 kg in the loads table on «Силовая» and saves
- **THEN** the student's copy of «Силовая» uses 80 kg as start and the template library entry is unchanged

### Requirement: Program is reachable from series, calendar, and student profile
The mobile app SHALL open the program screen from recurring series detail («Программа»), from a booked calendar event that belongs to that series, and from the student profile/hub when a series exists. Copy MUST be Russian.

#### Scenario: Open from series detail
- **WHEN** a trainer taps «Программа» on an active series
- **THEN** the program screen loads for that recurring booking

#### Scenario: Open from calendar
- **WHEN** a trainer opens program from a booked Monday session of the series
- **THEN** the same program screen opens with Monday's workouts visible
