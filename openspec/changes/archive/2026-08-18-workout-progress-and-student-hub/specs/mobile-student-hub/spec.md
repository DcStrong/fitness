## ADDED Requirements

### Requirement: Trainer can open a student hub with schedule workouts package and progress
The mobile app SHALL provide `/students/:id` (Russian) as a single scrolling page with: upcoming booked sessions (time + workout title or a without-program label), assigned workout copies, session package remaining/management already available to the trainer, and a progress section. The hub MUST NOT use a five-tab chrome. Opening a listed session SHALL go to the session workout page.

#### Scenario: Trainer opens linked student
- **WHEN** a trainer opens a linked student's hub
- **THEN** the page shows upcoming sessions, assigned copies, package status, and a progress section

#### Scenario: Upcoming session has a workout title
- **WHEN** an upcoming session has an attached copy
- **THEN** the hub row shows that workout title next to the time

### Requirement: Student can view own upcoming workouts and progress
The mobile app SHALL let a student open a Russian view of upcoming sessions, assigned copies, own package remaining, and progress charts for their logs. The student MUST NOT complete sessions or edit copies from this hub.

#### Scenario: Student opens own hub
- **WHEN** a student opens their training hub
- **THEN** they see upcoming sessions, assigned copies, package remaining, and progress without coach lifecycle actions
