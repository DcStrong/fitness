## ADDED Requirements

### Requirement: Login and Register use brand hero décor without contract changes
Login and Register SHALL present a brand hero region with the bundled Fitness Yoda illustration asset when available, soft mint decorative shapes, and a hero-to-form proportion consistent with `app/design/mapping-fitness-yoda.md` (~40–42% hero when the keyboard is closed). Email, password, role selection, validators, submission events, loading, errors, and navigation MUST remain unchanged.

#### Scenario: Successful login still works
- **WHEN** the user submits valid credentials on the polished Login screen
- **THEN** the existing authentication submission flow runs unchanged and navigates as before

#### Scenario: Register role unchanged
- **WHEN** the user selects trainer or student on polished Register
- **THEN** the form still submits the same role value expected by the authentication contract

#### Scenario: Compact height remains scrollable
- **WHEN** Login or Register is shown on a short viewport or with the keyboard open
- **THEN** the form remains scrollable without overflow and CTA/fields stay reachable
