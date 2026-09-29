## ADDED Requirements

### Requirement: Trainer opens student hub from the packages list
Tapping a linked student row on «Ученики и абонементы» SHALL open that student's hub (`/students/:id`) while package remaining on the list remains visible.

#### Scenario: Trainer opens a student from the list
- **WHEN** a trainer activates a student row on the packages list
- **THEN** the student hub is shown and still includes package remaining
