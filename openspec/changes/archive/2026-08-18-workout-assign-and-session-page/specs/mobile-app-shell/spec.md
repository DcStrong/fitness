## MODIFIED Requirements

### Requirement: Workout library uses existing plans routes
The Flutter app shell SHALL present the trainer template library on authenticated `/plans` routes. The trainer indexed bottom navigation SHALL include a «Тренировки» destination (dumbbell / `Icons.fitness_center`) that opens `/plans`. The student «Тренировки» destination SHALL remain `/sessions`. Unauthenticated access to plans routes SHALL redirect to login.

#### Scenario: Trainer opens planning from bottom nav
- **WHEN** an authenticated trainer selects «Тренировки» in the bottom navigation
- **THEN** the app shows the workout template library at `/plans`

#### Scenario: Unauthenticated redirected from plans
- **WHEN** a logged-out user hits plans routes
- **THEN** the router redirects to login

#### Scenario: Student bottom nav unchanged
- **WHEN** an authenticated student views the bottom navigation
- **THEN** «Тренировки» still opens `/sessions` and there is no extra plans tab
