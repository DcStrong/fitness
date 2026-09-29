# mobile-social Specification

## Purpose
Define authenticated Flutter social discovery, reviews, profile, and privacy experiences.

## Requirements

### Requirement: Flutter exposes trainer discovery
The Flutter app SHALL provide Russian authenticated UI for paginated trainer discovery with query/specialty/mode filters and loading, empty, error, and retry states.

#### Scenario: Student browses trainers
- **WHEN** a student opens «Тренеры»
- **THEN** the app shows only profiles returned by discovery and can load another bounded page

### Requirement: Flutter shows privacy-safe trainer profile
The Flutter app SHALL show a discoverable trainer's allowed profile, portfolio, rating, and reviews without presenting private identity or operational data.

#### Scenario: Unlinked student opens profile
- **WHEN** an unlinked student opens a trainer profile
- **THEN** the app explains that an invitation is required and does not offer direct booking

#### Scenario: Linked student opens profile
- **WHEN** a linked student opens the trainer profile
- **THEN** the app may offer navigation to the existing linked-coach booking flow

### Requirement: Flutter supports verified review flow
The Flutter app SHALL list the student's review-eligible completed Sessions, allow one rating/text submission, and allow editing that student's existing review.

#### Scenario: Student submits review
- **WHEN** the student selects an eligible completed Session and submits rating/text
- **THEN** the app refreshes eligibility, own reviews, and visible trainer rating

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

### Requirement: Flutter shows linked contacts for alternate coordination
The app SHALL display the linked-only contact projection inside the trainer's alternate-time flow, using available preferred channels and email fallback without exposing those fields on public trainer screens.

#### Scenario: Trainer opens contacts from pending request
- **WHEN** a trainer starts «Другое время» for a linked student's pending request
- **THEN** the app shows permitted contact actions and explains that agreement occurs outside Fitness Yoda

#### Scenario: Only email is available
- **WHEN** the linked student has no phone or Telegram configured
- **THEN** the app shows email as the fallback contact

### Requirement: Student social navigation is authenticated
The app SHALL expose authenticated student navigation for «Тренеры», «Тренировки», and «Профиль» while preserving existing trainer operational navigation.

#### Scenario: Logged-out deep link
- **WHEN** a logged-out user opens a trainer or profile route
- **THEN** existing auth redirects send the user to login
