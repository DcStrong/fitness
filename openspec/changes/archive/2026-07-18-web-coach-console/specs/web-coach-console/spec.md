## ADDED Requirements

### Requirement: Console shell provides navigation to coach areas
The authenticated web console SHALL provide a desktop-oriented shell with Russian navigation to at least: students/relationships, slots, sessions, tags, and plans.

#### Scenario: Trainer opens shell
- **WHEN** a trainer is signed in
- **THEN** they can navigate between the main coach sections without leaving the app shell

### Requirement: Trainer can view linked students
The console SHALL list coach–student relationships for the signed-in trainer using the existing relationships API.

#### Scenario: Linked students appear
- **WHEN** the trainer opens the students section and has active links
- **THEN** linked student identities (email or id) are shown

### Requirement: Trainer can manage schedule slots
The console SHALL let a trainer list and create (and delete when open) own availability slots via existing schedule APIs.

#### Scenario: Create slot from web
- **WHEN** a trainer submits a valid slot time range
- **THEN** the new open slot appears in their slots list

### Requirement: Trainer can manage sessions lifecycle
The console SHALL list the trainer's sessions and allow complete, cancel, and no-show actions on `booked` sessions, plus viewing session history, via existing session APIs.

#### Scenario: Complete booked session from web
- **WHEN** a trainer completes a booked session they coach
- **THEN** the session status becomes completed and the list refreshes

### Requirement: Trainer can manage tags and plans
The console SHALL allow creating tags, assigning them to linked students, and creating/editing own training plans with tags, via existing tags/plans APIs.

#### Scenario: Create tagged plan from web
- **WHEN** a trainer saves a plan with title and at least one own tag
- **THEN** the plan appears in their plans list with those tags
