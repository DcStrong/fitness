## ADDED Requirements

### Requirement: Session page shows workout content and lifecycle actions
The mobile app SHALL open `/sessions/:id` for a booked (and terminal) session with Russian copy showing time interval, counterpart, mode, goal and tags when a plan is attached, compact exercise rows, and package remaining when available. The coach SHALL get lifecycle actions complete / cancel / no-show (when permitted) and history on this page. The student SHALL see the same content read-only except cancel when permitted. If no plan is attached, the coach SHALL see «Выбрать тренировку».

#### Scenario: Coach opens booked session
- **WHEN** a coach opens a booked session that has an assigned copy
- **THEN** the page shows time, student, goal, tags, compact exercises, and complete/cancel/no-show actions

#### Scenario: Session without plan
- **WHEN** a coach opens a booked session with no `studentPlanId`
- **THEN** the page offers «Выбрать тренировку» and still allows lifecycle actions

#### Scenario: Student opens session
- **WHEN** the student of the session opens the page
- **THEN** they see the workout content and cannot complete or mark no-show

### Requirement: Coach can attach an assigned workout to a session
The mobile app SHALL let the session coach pick an existing assigned copy for that student or a template that is assigned (creating a copy if needed) and attach it to the session.

#### Scenario: Attach existing copy
- **WHEN** the coach selects an assigned copy of the session's student
- **THEN** the session page shows that workout's exercises

#### Scenario: Attach from template
- **WHEN** the coach selects a template that has no copy yet for that student
- **THEN** the app assigns a copy and attaches it to the session
