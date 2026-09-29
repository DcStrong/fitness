# mobile-plans-tags Specification

## Purpose
Flutter UI for trainer tag/plan management and student browsing of visible plans, including structured exercise content when present (Russian copy).

## Requirements

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

### Requirement: Student can browse visible plans
The mobile app SHALL let a student list visible plans and open a detail screen showing title, notes, tags, goal, and compact exercises when present (Russian labels).

#### Scenario: Student opens a visible plan
- **WHEN** a student selects a plan from the visible list
- **THEN** the app shows the plan title and notes or compact exercise content

### Requirement: Trainer plan detail shows compact structured content
When a plan has structured exercises, the mobile app SHALL show a compact Russian exercise list (`sets×reps` and weight or duration) together with goal and tags. When a plan has no exercises, the app MAY still show notes/body text.

#### Scenario: Detail with exercises
- **WHEN** a trainer or student opens a plan that has exercises
- **THEN** the screen shows title, goal, tags, and compact exercise rows rather than only a body text block

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
