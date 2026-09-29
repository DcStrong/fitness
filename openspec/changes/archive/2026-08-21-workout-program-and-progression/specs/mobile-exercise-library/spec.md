## ADDED Requirements

### Requirement: Exercise library edits stay base configuration
The mobile exercise library SHALL let the trainer create and edit an exercise's name, kind, and tags only. The library MUST NOT present per-student working weights. Personal kg MUST be edited on a workout template, student copy, program loads table, or session override.

#### Scenario: Create exercise has no student weight
- **WHEN** a trainer creates «Жим узким хватом» in the library
- **THEN** the form has name and kind (and tags) and no student-specific weight field

#### Scenario: Opening an exercise does not change copies
- **WHEN** a trainer renames an own exercise
- **THEN** assigned workout copies keep their stored set weights
