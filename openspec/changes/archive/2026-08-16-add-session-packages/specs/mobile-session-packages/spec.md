## ADDED Requirements

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
