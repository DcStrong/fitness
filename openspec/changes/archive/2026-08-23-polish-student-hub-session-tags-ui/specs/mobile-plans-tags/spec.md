## ADDED Requirements

### Requirement: Tags list looks like groups not per-row CRUD
The trainer tags screen (`/tags`) SHALL present each tag as a tappable group card (name plus a composition summary when the client can derive it from existing list/hub data: students and/or workouts and/or exercises). Tapping a card MUST open the existing tag hub. The list MUST NOT show a delete (trash) control on every row. Delete, if still available, SHALL live on the tag hub or an overflow on that hub. Create remains possible from the search field as today. Copy MAY stay «Теги»; the screen MUST follow the meaning of `app/design/generated/mock-tags-as-groups.png` without adding a bottom-nav «Группы» tab or renaming product destinations.

#### Scenario: Trainer opens tags from the library
- **WHEN** an authenticated trainer opens `/tags`
- **THEN** tags appear as group cards with composition when known, without a trash icon on each row

#### Scenario: Tap opens hub
- **WHEN** the trainer taps a tag card
- **THEN** the existing tag hub for that id opens

#### Scenario: Delete is not inline
- **WHEN** the trainer wants to remove a tag
- **THEN** they cannot delete it from a per-row trash on `/tags`; they use hub/overflow instead

## MODIFIED Requirements

### Requirement: Trainer can manage tags and plans in the app
The mobile app SHALL provide Russian UI for trainers to create, list, and delete own tags and assign them to linked students. Tag management SHALL be reachable from the trainer plans library (`/plans` → `/tags`) without a separate bottom-navigation destination. Creating a tag MUST be possible from the tags search field (not only a modal dialog) and MUST open the tag hub so the trainer can attach it immediately. The tags list SHALL be group cards rather than a CRUD table with inline delete. The plan editor SHALL let the trainer open tag management when they have no tags yet, rather than only showing a dead-end hint.

#### Scenario: Trainer opens tags from the library
- **WHEN** an authenticated trainer is on `/plans` and opens tag management
- **THEN** the app shows the existing tags screen where they can create, list, and assign tags as group cards

#### Scenario: Trainer creates a tag from search
- **WHEN** a trainer types a new tag name on `/tags` and confirms create
- **THEN** the tag is created and the app opens that tag's hub

#### Scenario: Trainer creates a tagged plan
- **WHEN** a trainer saves a plan with title and at least one own tag
- **THEN** the plan appears in their plans list with the selected tags

#### Scenario: Trainer assigns tag to linked student
- **WHEN** a trainer assigns a tag to a linked student from the UI
- **THEN** the assignment succeeds and the student can later see matching plans
