## ADDED Requirements

### Requirement: Trainer can manage tags from a hub and dismiss create safely
The mobile app SHALL provide Russian UI to open a tag hub from the tags list showing students, workouts, and exercises with that tag. Creating a tag via a dialog MUST dismiss on Back or Escape without crashing. Leaving `/tags` MUST pop to the previous route when possible, otherwise open the plans library — not Home.

#### Scenario: Trainer opens tag hub
- **WHEN** a trainer selects a tag from the tags list
- **THEN** the app shows students, workouts, and exercises linked to that tag

#### Scenario: Create tag dialog dismissed with escape
- **WHEN** a trainer opens the create-tag dialog and dismisses it with Escape or Back
- **THEN** the app returns to the tags list without a crash

### Requirement: Trainer can find students and workouts by tag
The mobile app SHALL let a trainer filter the plans library by own-tag chips (already on «Мои») and find students who have a tag from the tag hub. Assign sheets that pick students SHALL offer the same own-tag chips as a student filter.

#### Scenario: Filter library by tag chip
- **WHEN** a trainer selects a tag chip on «Мои»
- **THEN** only templates that include that tag remain in the list

#### Scenario: Hub shows students with the tag
- **WHEN** a trainer opens a tag that is assigned to a linked student
- **THEN** that student is listed on the hub
