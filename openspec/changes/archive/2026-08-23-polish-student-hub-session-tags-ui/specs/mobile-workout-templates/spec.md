## ADDED Requirements

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

## MODIFIED Requirements

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
