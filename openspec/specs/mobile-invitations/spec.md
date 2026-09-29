# mobile-invitations Specification

## Purpose
TBD - created by archiving change invitations-qr. Update Purpose after archive.
## Requirements
### Requirement: Trainer can show invite QR and copy link
The mobile app SHALL provide a trainer screen to create (or refresh) an invitation and display a QR code encoding the invite deep link, plus an action to copy the same link to the clipboard. UI copy MUST be in Russian.

#### Scenario: Trainer opens invite screen
- **WHEN** an authenticated trainer opens the invite screen and creation succeeds
- **THEN** the app shows a QR for the invite URL and a control to copy the link

#### Scenario: Copy link
- **WHEN** the trainer taps copy
- **THEN** the invite URL is placed on the clipboard

### Requirement: Student can accept invitation from deep link or manual token
The mobile app SHALL support opening an invite deep link (`fitnessyoda://invite/<token>` or HTTPS placeholder path `/i/<token>`) and, when the user is authenticated as a student (or has accept permission), calling accept and navigating to home with relationship context. If unauthenticated, the app MUST retain the pending token and continue to login/register, then offer accept.

#### Scenario: Authenticated student opens invite link
- **WHEN** a logged-in student opens a valid invite deep link
- **THEN** the app calls accept and on success navigates to home showing the linked coach context

#### Scenario: Unauthenticated user opens invite link
- **WHEN** a logged-out user opens an invite deep link
- **THEN** the app stores the pending token, shows auth screens, and after login/register proceeds to accept

#### Scenario: Accept failure surfaces error
- **WHEN** accept fails (expired, revoked, invalid)
- **THEN** the app shows a Russian error message and does not claim a successful link

### Requirement: Home shows relationship context after link
After a successful accept (or when relationships exist), the home (or equivalent) screen SHALL show at least that the user is linked to a coach (student) or has invitees/students (trainer) in a minimal stub suitable for MVP.

#### Scenario: Student home after accept
- **WHEN** the student reaches home after accepting an invitation
- **THEN** the UI indicates the linked coach (email or id) in Russian copy

