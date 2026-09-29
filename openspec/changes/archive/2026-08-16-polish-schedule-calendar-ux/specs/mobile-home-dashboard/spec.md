## ADDED Requirements

### Requirement: Upcoming trainings section can collapse
The mobile Home dashboard SHALL present the main upcoming/current schedule under a Russian «Предстоящие тренировки» (or equivalent) header that can expand and collapse like daily History. The upcoming section MUST default to expanded. Collapsing MUST hide the upcoming session rows while keeping the header and count visible; expanding MUST show the rows again. History collapse behavior remains unchanged.

#### Scenario: Home opens with upcoming expanded
- **WHEN** Home loads with at least one upcoming or in-progress training
- **THEN** the upcoming header shows the count and the session rows are visible by default

#### Scenario: User collapses upcoming
- **WHEN** the user activates the upcoming header while it is expanded
- **THEN** the upcoming rows are hidden while the header and count remain visible

#### Scenario: User expands upcoming again
- **WHEN** the user activates the collapsed upcoming header
- **THEN** the upcoming rows are displayed again in chronological order
