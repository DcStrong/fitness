## ADDED Requirements

### Requirement: Student reviews only an own completed Session
The system SHALL allow a user with `reviews:create_own` to create a rating from 1 to 5 and optional bounded plain-text review only when the actor is the Session student and the Session status is `completed`.

#### Scenario: Student reviews completed Session
- **WHEN** the Session student reviews their completed Session
- **THEN** the review is linked to that Session and its coach

#### Scenario: Non-completed Session is ineligible
- **WHEN** the student attempts to review a booked, cancelled, or no-show Session
- **THEN** the system rejects the review

#### Scenario: Outsider cannot review
- **WHEN** a user who is not the Session student attempts to review it
- **THEN** the system rejects the request

### Requirement: Session has at most one review
The system SHALL enforce exactly one review row per Session with a database uniqueness constraint and race-safe error handling.

#### Scenario: Duplicate review is rejected
- **WHEN** the student submits a second create request for the same Session
- **THEN** the system rejects it and the trainer rating counts the Session once

### Requirement: Student edits only own review
The system SHALL allow a user with `reviews:update_own` to update rating/text only on a review where they are the student. Trainers and other students MUST NOT edit it.

#### Scenario: Student corrects rating
- **WHEN** the review author replaces a valid rating
- **THEN** the review is updated and subsequent rating aggregates reflect the new value

#### Scenario: Trainer cannot edit review
- **WHEN** the reviewed trainer attempts to change rating or text
- **THEN** the system rejects the request

### Requirement: Student can list review eligibility and own reviews
The system SHALL expose the authenticated student's completed Sessions without a review as eligible, and SHALL expose that student's existing reviews separately.

#### Scenario: Completed unreviewed Session appears
- **WHEN** a student requests review eligibility
- **THEN** their completed Sessions without reviews are returned and other students' Sessions are absent

### Requirement: Trainer rating is derived
The system SHALL derive `averageRating` and `reviewCount` from stored reviews rather than a separately mutable balance. Public rating fields SHALL be omitted when trainer privacy hides rating.

#### Scenario: Second review changes aggregate
- **WHEN** a trainer receives another eligible review
- **THEN** the next rating read returns the recalculated average and count

#### Scenario: Rating privacy is disabled
- **WHEN** a trainer sets `showRating=false`
- **THEN** public profile/discovery responses omit rating fields while owner reads remain available

### Requirement: Review visibility follows trainer privacy
Public review text SHALL be returned only for a discoverable trainer with `showReviews=true`. Trainer owner reads SHALL remain available regardless of public visibility and MUST NOT disclose student email.

#### Scenario: Trainer hides review list
- **WHEN** a trainer disables public review visibility
- **THEN** public readers receive no review text while the trainer still sees reviews in the owner console
