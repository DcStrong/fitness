## ADDED Requirements

### Requirement: Authenticated routes use role-aware bottom navigation
The Flutter app shell SHALL provide a Fitness Yoda bottom navigation experience for authenticated primary destinations, preserve existing `go_router` route protection and deep-link behavior, and expose only destinations appropriate to the authenticated trainer or student.

#### Scenario: Authenticated user enters the app shell
- **WHEN** a logged-in user opens a primary authenticated destination
- **THEN** the bottom navigation is visible with the current destination represented by a mint active pill, primary icon, and label

#### Scenario: User changes primary destination
- **WHEN** the user selects an available inactive navigation item
- **THEN** the router displays the corresponding existing feature destination and updates the active navigation state

#### Scenario: Trainer and student have different destinations
- **WHEN** the authenticated user's role does not support a navigation destination
- **THEN** that destination is hidden or replaced by the role-appropriate destination without bypassing route permissions

#### Scenario: User opens an unauthenticated route
- **WHEN** Login or Register is displayed
- **THEN** the authenticated bottom navigation shell is not visible

#### Scenario: Unauthenticated user opens a protected shell destination
- **WHEN** a logged-out user attempts to open a protected navigation destination
- **THEN** the existing authentication redirect sends the user to Login
