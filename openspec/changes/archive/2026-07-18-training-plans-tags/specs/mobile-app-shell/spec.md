## ADDED Requirements

### Requirement: Router exposes plans and tags routes
The Flutter app shell SHALL register authenticated routes for trainer tag/plan management and student visible plans (e.g. `/tags`, `/plans`, `/plans/:id`), gated by existing auth redirect rules.

#### Scenario: Authenticated user opens plans route
- **WHEN** a logged-in user navigates to the plans route
- **THEN** the plans screen is shown

#### Scenario: Unauthenticated redirected from plans or tags
- **WHEN** a logged-out user hits plans or tags routes
- **THEN** the router redirects to login
