## ADDED Requirements

### Requirement: Session page can show and attach multiple workouts
The mobile session page SHALL list attached workouts in order (title + compact exercises from the session snapshot). The coach SHALL be able to add another assigned copy or template (assign if needed), reorder is not required in v1, and remove one workout without detaching the others. Empty state copy remains «Выбрать тренировку» and MAY add a second workout after the first is attached. A coach edit of snapshot weights on this page MUST mark the session overridden so the series program will not overwrite it on the next apply.

#### Scenario: Two workouts on one session
- **WHEN** the coach attaches «Силовая» and then «Кор»
- **THEN** the page shows both sections and the student sees both read-only

#### Scenario: Remove one of two
- **WHEN** the coach removes «Кор» and leaves «Силовая»
- **THEN** the session still shows «Силовая»

#### Scenario: Override is sticky
- **WHEN** the coach changes bench to 82.5 kg on this session and a later program apply runs without force
- **THEN** that session still shows 82.5 kg
