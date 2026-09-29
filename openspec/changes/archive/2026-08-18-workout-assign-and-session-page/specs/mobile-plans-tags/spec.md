## MODIFIED Requirements

### Requirement: Trainer can manage tags and plans in the app
The mobile app SHALL provide Russian UI for trainers to create, list, and delete own tags and assign them to linked students. Tag management SHALL be reachable from the trainer plans library (`/plans` → `/tags`) without a separate bottom-navigation destination. The plan editor SHALL let the trainer open tag management when they have no tags yet, rather than only showing a dead-end hint.

#### Scenario: Trainer opens tags from the library
- **WHEN** an authenticated trainer is on `/plans` and opens tag management
- **THEN** the app shows the existing tags screen where they can create, list, delete, and assign tags

#### Scenario: Trainer creates a tagged plan
- **WHEN** a trainer saves a plan with title and at least one own tag
- **THEN** the plan appears in their plans list with the selected tags

#### Scenario: Trainer assigns tag to linked student
- **WHEN** a trainer assigns a tag to a linked student from the UI
- **THEN** the assignment succeeds and the student can later see matching plans
