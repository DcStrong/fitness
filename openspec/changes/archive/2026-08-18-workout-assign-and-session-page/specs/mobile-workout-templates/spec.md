## ADDED Requirements

### Requirement: Trainer can assign a template from the library
The mobile app SHALL provide a Russian «Назначить» action on an own template that lets the trainer pick linked students and/or own tags and confirms assignment. Success MUST result in student copies without editing the template in place.

#### Scenario: Assign from template detail
- **WHEN** a trainer confirms assign to one linked student
- **THEN** that student has an assigned copy and the template content is unchanged

### Requirement: Trainer library is a primary destination
The mobile app SHALL treat `/plans` as a primary trainer destination reachable from bottom navigation, with tag management available from that library.

#### Scenario: Library is the assign surface
- **WHEN** a trainer opens «Тренировки» from the bottom bar
- **THEN** they can browse own templates and catalog and reach assign and tag management from there
