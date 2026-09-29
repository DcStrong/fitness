# mobile-session-packages Specification

## Purpose
Flutter UX for session packages: trainer create/extend/archive and remaining display, student Home remaining indicator, and in-app exhaustion prompt after qualifying Session terminals.
## Requirements
### Requirement: Trainer sees and manages package remaining on mobile
The Flutter app SHALL show the trainer the remaining session count for linked students that have a SessionPackage, and SHALL allow creating, extending, and archiving a package from a student-scoped flow (Russian copy). When no package exists, the UI SHALL offer create. When status is exhausted or expired, the UI SHALL prompt to extend or issue a new package after archive.

#### Scenario: Trainer sees remaining on student list
- **WHEN** a trainer opens the linked-students context that surfaces packages
- **THEN** each student with an active package shows «осталось N» (or equivalent Russian copy)

#### Scenario: Trainer creates package
- **WHEN** a trainer submits a valid N (and optional expiry) for a linked student without an active package
- **THEN** the app creates the package and shows the new remaining count

#### Scenario: Trainer extends exhausted package
- **WHEN** a trainer extends an exhausted package with additional sessions
- **THEN** the app refreshes to show active status and updated remaining

### Requirement: Student sees own package remaining on Home
The Flutter app SHALL show a student with an active package a concise Home (or equivalent primary) indicator of remaining sessions. When the package is exhausted or expired, the app SHALL show a short Russian hint to contact the trainer — without finance wallet aggregates.

#### Scenario: Student sees remaining on Home
- **WHEN** a linked student with an active package opens Home
- **THEN** the app shows remaining session count for that package

#### Scenario: Student sees exhausted hint
- **WHEN** the student's package is exhausted
- **THEN** the app shows that the package has ended and to contact the trainer

### Requirement: Trainer is prompted when a package becomes exhausted
After a trainer completes a Session or marks a chargeable no_show that exhausts the package, the Flutter app SHALL show an in-app signal (snackbar or banner) offering to extend the package. Push notifications are NOT required.

#### Scenario: Exhaustion after complete
- **WHEN** a trainer marks a Session completed and the API signals package exhaustion
- **THEN** the app shows an in-app prompt to renew/extend the package

### Requirement: Trainer filters students by payment and pending-request status
On the trainer «Ученики и абонементы» list the app SHALL provide Russian filter chips: «Все», «Оплачен», «Не оплачен», «Ожидает». Categorization MUST be mutually exclusive with priority: (1) **Ожидает** — the student has at least one non-expired pending BookingRequest in the trainer inbox; (2) **Оплачен** — the student has an `active` SessionPackage; (3) **Не оплачен** — linked student without an active package. Default filter is «Все». Loading MUST use existing relationships, packages, and booking-requests inbox APIs without a new Nest endpoint.

#### Scenario: Filter paid students
- **WHEN** a trainer selects «Оплачен»
- **THEN** only linked students with an active package are listed

#### Scenario: Filter unpaid students
- **WHEN** a trainer selects «Не оплачен»
- **THEN** only linked students without an active package and without a pending inbox request (per priority rules) are listed

#### Scenario: Filter waiting students
- **WHEN** a trainer selects «Ожидает»
- **THEN** students who have a pending booking request awaiting trainer response are listed

#### Scenario: Pending outranks package
- **WHEN** a linked student has both an active package and a pending booking request
- **THEN** that student appears under «Ожидает» and not under «Оплачен» while the waiting filter semantics apply

### Requirement: Trainer opens student hub from the packages list
Tapping a linked student row on «Ученики и абонементы» SHALL open that student's hub (`/students/:id`) while package remaining on the list remains visible.

#### Scenario: Trainer opens a student from the list
- **WHEN** a trainer activates a student row on the packages list
- **THEN** the student hub is shown and still includes package remaining

