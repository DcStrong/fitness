## ADDED Requirements

### Requirement: Router exposes authenticated social routes
The Flutter app shell SHALL register authenticated routes for trainer discovery/public profile, own profile/privacy, review eligibility, and review editing.

#### Scenario: Authenticated student opens discovery
- **WHEN** a signed-in student navigates to the trainers route
- **THEN** the discovery screen is shown

#### Scenario: Logged-out user opens social route
- **WHEN** a logged-out user opens any social/profile/review route
- **THEN** existing auth redirects send the user to login

### Requirement: Student shell exposes social navigation
The authenticated student shell SHALL provide clear navigation among trainers, training Sessions, and own profile without exposing trainer-only management routes.

#### Scenario: Student sees primary destinations
- **WHEN** a student reaches the authenticated shell
- **THEN** «Тренеры», «Тренировки», and «Профиль» destinations are available
