# mobile-student-hub Specification

## Purpose
Flutter student hub (`/students/:id` for a trainer, own hub for a student): upcoming sessions, assigned workout copies, package remaining, and progress on one scrolling page.

## Requirements

### Requirement: Trainer can open a student hub with schedule workouts package and progress
The mobile app SHALL provide `/students/:id` (Russian) as a single scrolling page whose primary content is the student as a person (name, package remaining, next session), this week's workouts, assigned workout copies with assign, and a progress section. Upcoming sessions MAY appear as the header next-session row and/or the this-week strip rather than a long equal-weight list of session cards at the top. Session package remaining/management MUST remain reachable (header + Абонемент action). The hub MUST NOT use a five-tab chrome. Opening a listed session SHALL go to the session workout page.

#### Scenario: Trainer opens linked student
- **WHEN** a trainer opens a linked student's hub
- **THEN** the page shows the person header (including package status), this-week or next session, assigned copies, and a progress section

#### Scenario: Upcoming session has a workout title
- **WHEN** an upcoming session has an attached copy
- **THEN** the hub shows that workout title next to the time in the header and/or this-week strip

### Requirement: Student can view own upcoming workouts and progress
The mobile app SHALL let a student open a Russian view of upcoming sessions, assigned copies, own package remaining, and progress charts for their logs. The student MUST NOT complete sessions or edit copies from this hub. The trainer-only 2×2 action grid (Записать / Назначить / Абонемент / Программа) MUST NOT appear on the student's own hub.

#### Scenario: Student opens own hub
- **WHEN** a student opens their training hub
- **THEN** they see upcoming sessions, assigned copies, package remaining, and progress without coach lifecycle actions

### Requirement: Trainer hub uses a person header week strip and compact action grid
The trainer student hub (`/students/:id`) SHALL present a person header (display name, package remaining and/or expiry when known, next booked session as a tappable row), a «На этой неделе» strip of weekday + workout titles derived from the existing series program or this week's booked sessions, a compact 2×2 action grid (Записать / Назначить / Абонемент / Программа) that is visually secondary to the person and week content, then assigned workout cards with a «Назначить» text action, then progress. The hub MUST NOT present those four actions as a vertical ribbon of equal-weight full-width CTA cards. The hub MUST NOT introduce a five-tab chrome. Meaning of `app/design/generated/mock-student-hub-a-profile.png` and `mock-student-hub-b-actions.png` SHALL be followed; pixel-perfect layout, stock photos, and extra mock chrome MUST NOT be required.

#### Scenario: Trainer opens linked student
- **WHEN** a trainer opens a linked student's hub
- **THEN** they see the person header, this-week strip, compact action grid, assigned workouts, and progress on one scroll

#### Scenario: Next session in header opens the session page
- **WHEN** the header shows a next booked session and the trainer taps it
- **THEN** the app opens that session workout page

#### Scenario: Actions are a compact grid not a CTA ribbon
- **WHEN** the trainer hub is shown
- **THEN** Записать, Назначить, Абонемент, and Программа appear as a compact 2×2 grid, not as four stacked equal primary buttons

#### Scenario: Assign from workouts section
- **WHEN** the trainer activates «Назначить» in the workouts section
- **THEN** the existing assign-to-this-student flow runs without leaving the hub's student context

#### Scenario: Program from week header or grid
- **WHEN** a series exists and the trainer activates «Программа» from the week section or the action grid
- **THEN** the existing program screen for that recurring booking opens

#### Scenario: No series yet
- **WHEN** the student has no recurring series
- **THEN** the this-week strip is empty or omitted and Программа still offers the existing series/program entry the trainer already has, without inventing a new API
