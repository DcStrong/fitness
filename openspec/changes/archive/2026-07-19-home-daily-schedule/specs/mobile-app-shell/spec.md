## MODIFIED Requirements

### Requirement: Home shows signed-in profile stub
The authenticated Home route SHALL present a role-aware daily workspace instead of a signed-in profile stub. Trainer Home SHALL prioritize today's sessions and operational destinations; authenticated profile details and logout SHALL remain available through the existing Profile destination.

#### Scenario: Trainer reaches Home after login
- **WHEN** an authenticated trainer is redirected to `/home`
- **THEN** the daily schedule dashboard is shown within the authenticated shell

#### Scenario: Profile and logout remain available
- **WHEN** Home no longer displays the signed-in profile stub
- **THEN** the authenticated user can still access profile details and logout through the Profile destination

#### Scenario: Student completes login
- **WHEN** an authenticated student completes login
- **THEN** the existing student initial destination remains unchanged and the change does not force the student onto `/home`
