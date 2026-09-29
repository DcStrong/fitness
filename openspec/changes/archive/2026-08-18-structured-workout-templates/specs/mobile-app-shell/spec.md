## ADDED Requirements

### Requirement: Workout library uses existing plans routes
The Flutter app shell SHALL present trainer template library (own templates and catalog) and the structured editor on the existing authenticated `/plans` routes without adding a new indexed bottom-navigation destination.

#### Scenario: Trainer opens planning
- **WHEN** an authenticated trainer navigates to `/plans`
- **THEN** the workout template library is shown inside the existing shell

#### Scenario: Unauthenticated redirected from plans
- **WHEN** a logged-out user hits plans routes
- **THEN** the router redirects to login
