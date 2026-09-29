## ADDED Requirements

### Requirement: Trainer can manage schedule and book for student in app
The mobile app SHALL provide a Russian UI for trainers to create/list availability slots and to book a linked student into a free slot.

#### Scenario: Trainer adds a slot
- **WHEN** a trainer submits a valid slot form
- **THEN** the slot appears in their schedule list

#### Scenario: Trainer books linked student
- **WHEN** a trainer selects a free slot and a linked student and confirms
- **THEN** the app creates a booked session and shows it in the sessions list

### Requirement: Student can browse linked coach slots and book
The mobile app SHALL let a student see free slots of a linked coach and book one, with Russian labels and errors.

#### Scenario: Student books a slot
- **WHEN** a linked student selects a free slot and confirms booking
- **THEN** the app creates a booked session and shows success / lists the session

#### Scenario: Booking error surfaced
- **WHEN** booking fails (taken / forbidden)
- **THEN** the app shows a Russian error and does not claim success

### Requirement: Both roles can see upcoming sessions list
The app SHALL show a simple list of the current user's sessions (time, counterpart email/id, status).

#### Scenario: Home or sessions screen shows bookings
- **WHEN** an authenticated user opens the sessions list
- **THEN** their booked sessions are displayed
