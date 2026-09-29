## MODIFIED Requirements

### Requirement: Flutter manages own profile and privacy
The Flutter app SHALL allow both roles to edit own public profile fields, supported privacy settings, optional phone/Telegram contacts, and preferred contact channels. Trainer publishing controls SHALL be shown only when applicable, while contact copy SHALL explain linked-only visibility and email fallback.

#### Scenario: User saves preferred contacts
- **WHEN** a user enters valid phone/Telegram values, selects available preferred channels, and saves
- **THEN** the app reflects the normalized owner profile returned by the API

#### Scenario: Preferred channel is incomplete
- **WHEN** the user selects phone or Telegram without supplying a valid corresponding value
- **THEN** the form shows a Russian validation error and does not claim success

#### Scenario: Trainer enables discovery
- **WHEN** a trainer saves required public profile data and enables publication
- **THEN** the app reflects the published owner state while explaining that contacts remain private

#### Scenario: Student controls review attribution
- **WHEN** a student disables reviewer-name visibility
- **THEN** the setting is saved and the UI explains that public reviews will be anonymous

## ADDED Requirements

### Requirement: Flutter shows linked contacts for alternate coordination
The app SHALL display the linked-only contact projection inside the trainer's alternate-time flow, using available preferred channels and email fallback without exposing those fields on public trainer screens.

#### Scenario: Trainer opens contacts from pending request
- **WHEN** a trainer starts «Другое время» for a linked student's pending request
- **THEN** the app shows permitted contact actions and explains that agreement occurs outside Fitness Yoda

#### Scenario: Only email is available
- **WHEN** the linked student has no phone or Telegram configured
- **THEN** the app shows email as the fallback contact
