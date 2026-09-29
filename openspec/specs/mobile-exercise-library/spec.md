# mobile-exercise-library Specification

## Purpose
Flutter trainer/student exercise library: a distinct `/plans` mode for exercises, tagging (including catalog), assign without cloning, and a read-only student list.

## Requirements

### Requirement: Trainer library includes exercises separately from workouts
The mobile app SHALL present exercises as a distinct Russian mode of the trainer library (`/plans`), not mixed into template cards. The trainer MUST be able to search, filter by own tags, attach tags (including to catalog exercises), and assign one or more exercises to linked students and/or via tags. Creating a workout template remains a separate action.

#### Scenario: Trainer opens exercises mode
- **WHEN** an authenticated trainer switches the library to exercises
- **THEN** the app lists exercises (own and catalog) with tags, not template cards

#### Scenario: Trainer assigns five exercises to a student
- **WHEN** a trainer selects five exercises and confirms a linked student
- **THEN** those exercises are assigned to the student without creating a template

### Requirement: Student can browse visible and assigned exercises
The mobile app SHALL let a student list exercises that are visible via shared tags or explicitly assigned, in Russian, separately from workout templates. The student MUST NOT mutate exercises.

#### Scenario: Student sees tagged exercises
- **WHEN** a student and an exercise share a tag from a linked coach
- **THEN** that exercise appears in the student's exercise list

#### Scenario: Student sees explicitly assigned exercises
- **WHEN** a coach assigned exercises without a shared tag
- **THEN** those exercises still appear in the student's exercise list

### Requirement: Exercise library edits stay base configuration
The mobile exercise library SHALL let the trainer create and edit an exercise's name, kind, and tags only. The library MUST NOT present per-student working weights. Personal kg MUST be edited on a workout template, student copy, program loads table, or session override.

#### Scenario: Create exercise has no student weight
- **WHEN** a trainer creates «Жим узким хватом» in the library
- **THEN** the form has name and kind (and tags) and no student-specific weight field

#### Scenario: Opening an exercise does not change copies
- **WHEN** a trainer renames an own exercise
- **THEN** assigned workout copies keep their stored set weights
