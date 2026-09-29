## ADDED Requirements

### Requirement: Trainer plan detail shows compact structured content
When a plan has structured exercises, the mobile app SHALL show a compact Russian exercise list (`sets×reps` and weight or duration) together with goal and tags. When a plan has no exercises, the app MAY still show notes/body text.

#### Scenario: Detail with exercises
- **WHEN** a trainer or student opens a plan that has exercises
- **THEN** the screen shows title, goal, tags, and compact exercise rows rather than only a body text block

## MODIFIED Requirements

### Requirement: Trainer can manage tags and plans in the app
The mobile app SHALL provide Russian UI for trainers to create/list/delete tags, assign tags to linked students, and create/edit/list own training plans (title, notes, goal, tags, and structured exercises).

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
