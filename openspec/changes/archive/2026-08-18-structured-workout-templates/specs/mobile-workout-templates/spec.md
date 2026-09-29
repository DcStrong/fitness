## ADDED Requirements

### Requirement: Trainer library separates own templates from catalog
The mobile app SHALL present the trainer plans destination as a two-mode library: «Мои» (own templates) and «База» (catalog seed). The app MUST NOT mix both sources into one undifferentiated list. Search and own-tag chips SHALL filter the visible list. Each card MUST show title, goal chip, up to two tags, and exercise count — not gender, difficulty, or a per-set accordion.

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
