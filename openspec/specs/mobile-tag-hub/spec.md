# mobile-tag-hub Specification

## Purpose
Flutter trainer tag hub at `/tags/:id`: students, own templates, and exercises for one tag, reachable from the tags list.

## Requirements

### Requirement: Trainer can browse a tag hub
The mobile app SHALL provide a Russian tag hub at `/tags/:id` reachable from the tags list. The hub MUST list linked students with the tag, own templates and student copies with the tag, and exercises with the tag. The hub MUST let the trainer search/filter those entities by type (students / workouts / exercises) and attach the tag to students, workouts, and exercises from that screen. Tapping a workout MUST open its existing detail/editor. Tapping a student MUST open that student's hub.

#### Scenario: Open hub from tags list
- **WHEN** a trainer taps a tag in the list
- **THEN** the hub shows that tag's students, workouts, and exercises

#### Scenario: Filter hub by entity type
- **WHEN** a trainer opens a tag hub and selects «Ученики»
- **THEN** workouts and exercises are hidden and students remain

#### Scenario: Attach tag to a student from the hub
- **WHEN** a trainer attaches the tag to a linked student from the hub
- **THEN** that student appears in the hub students list

#### Scenario: Empty hub sections
- **WHEN** a tag has no exercises yet
- **THEN** the exercises section is empty and the rest of the hub still loads
