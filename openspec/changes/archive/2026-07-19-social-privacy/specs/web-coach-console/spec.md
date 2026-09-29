## ADDED Requirements

### Requirement: Console shell exposes public profile management
The authenticated web coach console SHALL include Russian navigation to the trainer's public profile, portfolio, privacy, preview, and received reviews.

#### Scenario: Trainer opens public profile section
- **WHEN** a signed-in trainer selects «Публичный профиль»
- **THEN** the console navigates to the coach-only profile management page

#### Scenario: Student cannot access social management
- **WHEN** an authenticated student attempts to open the profile management page
- **THEN** the existing console shell denies access
