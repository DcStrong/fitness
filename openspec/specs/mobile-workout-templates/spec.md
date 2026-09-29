# mobile-workout-templates Specification

## Purpose
Flutter trainer library for own templates vs catalog seed, compact cards, and a single-screen structured editor (Russian copy).

## Requirements

### Requirement: Trainer library separates own templates from catalog
The mobile app SHALL present the trainer plans destination as a library with «Мои» (own templates), «База» (catalog seed), and a separate exercises mode (see mobile-exercise-library). The app MUST NOT mix templates and exercises into one undifferentiated list. Search and a compact set of own-tag chips (plus «Ещё» when needed) SHALL filter the visible list. Each template card MUST show title, goal chip, up to two tags, and exercise count — not gender, difficulty, or a per-set accordion.

#### Scenario: Trainer opens own templates
- **WHEN** an authenticated trainer opens «Планирование» on «Мои»
- **THEN** the app lists that trainer's templates as compact cards with title, goal, tags, and exercise count

#### Scenario: Trainer browses catalog
- **WHEN** the trainer switches to «База»
- **THEN** the app lists catalog seed templates without mixing in the trainer's own templates

#### Scenario: Trainer clones catalog template
- **WHEN** the trainer activates «Добавить к себе» on a catalog template
- **THEN** a copy appears under «Мои» as an own editable template

### Requirement: Trainer edits a template on one screen
The mobile app SHALL provide a single Russian editor for creating or updating an own template: required title, goal pills (Набор / Похудение / Общее), own tags, notes, and an exercise list. Adding an exercise MUST use search of own+catalog exercises or create-by-name. Each exercise row MUST summarize as compact `sets×reps` (and weight or duration) plus rest — the editor MUST NOT expand every identical set as its own accordion row. Saving with empty title MUST be rejected in the UI.

#### Scenario: Trainer creates template with exercises
- **WHEN** a trainer enters a title, selects a goal, adds at least one exercise with sets, and saves
- **THEN** the template appears in «Мои» with that goal and exercise count

#### Scenario: Exercise row stays compact
- **WHEN** a trainer adds an exercise with three identical sets of 12 reps
- **THEN** the list shows one row summarizing `3×12` rather than three expanded set rows

#### Scenario: Empty title blocked
- **WHEN** a trainer attempts to save without a title
- **THEN** the app does not submit and explains that a name is required

### Requirement: Trainer can assign a template from the library
The mobile app SHALL provide a Russian «Назначить» action on an own template that lets the trainer pick linked students and/or own tags and confirms assignment. Success MUST result in student copies without editing the template in place.

#### Scenario: Assign from template detail
- **WHEN** a trainer confirms assign to one linked student
- **THEN** that student has an assigned copy and the template content is unchanged

### Requirement: Trainer can assign multiple own templates to one student
The mobile app SHALL provide a Russian flow to select two or more own templates and assign them to one linked student, producing a student copy per template. The flow MUST NOT require opening each template detail in turn.

#### Scenario: Multi-select assign
- **WHEN** a trainer selects two own templates and confirms one linked student
- **THEN** both templates are assigned as copies to that student

### Requirement: Trainer library is a primary destination
The mobile app SHALL treat `/plans` as a primary trainer destination reachable from bottom navigation, with tag management available from that library.

#### Scenario: Library is the assign surface
- **WHEN** a trainer opens «Тренировки» from the bottom bar
- **THEN** they can browse own templates and catalog and reach assign and tag management from there

### Requirement: Trainer can edit working weights for a whole workout in one table
The mobile template and student-copy editors SHALL show a Russian «Нагрузки» table listing `weight_reps` exercises with a single weight field per exercise that applies to all sets of that exercise. The trainer MUST be able to change those weights without expanding each exercise into per-set accordions. Saving MUST persist via plan loads or equivalent nested update without changing the parent catalog exercise.

#### Scenario: Set all strength loads on one screen
- **WHEN** a trainer opens «Силовая» and sets bench 80 kg and row 60 kg in «Нагрузки» and saves
- **THEN** the workout stores those weights on the corresponding sets and the exercise library entries are unchanged

#### Scenario: Bodyweight rows omitted from loads table
- **WHEN** the workout includes pull-ups as `bodyweight_reps`
- **THEN** pull-ups do not appear as a weight field in «Нагрузки»

### Requirement: Library tag filters stay compact with a search sheet for the rest
On the trainer plans library (`/plans`, modes «Мои» / «База» / «Упражнения»), the mobile app SHALL show at most four or five own-tag chips at once: popular and/or recently used tags for that trainer, plus an «Ещё» chip. Activating «Ещё» (or an equivalent search affordance in that row) MUST open a Russian bottom sheet matching the meaning of `app/design/generated/mock-tags-search-sheet.png`: search field, matching tag list, selected chips, apply/dismiss. Tags beyond the compact row MUST NOT remain as an endless horizontal chip strip. The sheet MUST filter the visible library list by the confirmed tag selection. Creating a brand-new tag remains on `/tags`, not as extra mock filters (difficulty, equipment, muscles) on this sheet.

#### Scenario: Few tags stay on the row
- **WHEN** a trainer has three own tags
- **THEN** those tags can appear as chips without requiring «Ещё»

#### Scenario: Many tags hide behind Ещё
- **WHEN** a trainer has more than five own tags
- **THEN** the library shows at most five chips including «Ещё», and the remaining tags are reachable only via the search sheet

#### Scenario: Sheet filters the list
- **WHEN** the trainer searches in the sheet, selects a tag, and confirms
- **THEN** the library list is filtered to templates or exercises with that tag and the sheet closes
