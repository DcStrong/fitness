## ADDED Requirements

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
The Flutter app SHALL allow both roles to edit own profile and supported privacy settings. Trainer publishing controls SHALL be shown only when applicable.

#### Scenario: Trainer enables discovery
- **WHEN** a trainer saves required profile data and enables publication
- **THEN** the app reflects the published owner state returned by the API

#### Scenario: Student controls review attribution
- **WHEN** a student disables reviewer-name visibility
- **THEN** the setting is saved and the UI explains that public reviews will be anonymous

### Requirement: Student social navigation is authenticated
The app SHALL expose authenticated student navigation for «Тренеры», «Тренировки», and «Профиль» while preserving existing trainer operational navigation.

#### Scenario: Logged-out deep link
- **WHEN** a logged-out user opens a trainer or profile route
- **THEN** existing auth redirects send the user to login
