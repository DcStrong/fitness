## ADDED Requirements

### Requirement: Trainer can browse a tag hub
The mobile app SHALL provide a Russian tag hub at `/tags/:id` reachable from the tags list. The hub MUST list linked students with the tag, own templates with the tag, and exercises with the tag. Tapping a workout or exercise MUST open its existing detail/editor. Tapping a student MUST start assign or show that student's tagged content without adding a new bottom-nav destination.

#### Scenario: Open hub from tags list
- **WHEN** a trainer taps a tag in the list
- **THEN** the hub shows that tag's students, workouts, and exercises

#### Scenario: Empty hub sections
- **WHEN** a tag has no exercises yet
- **THEN** the exercises section is empty and the rest of the hub still loads
