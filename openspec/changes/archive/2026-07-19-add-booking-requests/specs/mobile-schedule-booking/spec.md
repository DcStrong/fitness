## MODIFIED Requirements

### Requirement: Trainer can manage schedule and book for student in app
The mobile app SHALL provide a Russian UI for trainers to create/list availability slots, directly book a linked student into a free slot, and manage an owner-scoped BookingRequest inbox.

#### Scenario: Trainer adds a slot
- **WHEN** a trainer submits a valid slot form
- **THEN** the slot appears in their schedule list

#### Scenario: Trainer books linked student directly
- **WHEN** a trainer selects a free slot and a linked student and confirms
- **THEN** the app creates a booked Session and shows it in the sessions list without creating a BookingRequest

#### Scenario: Trainer opens request inbox
- **WHEN** a trainer opens «Заявки»
- **THEN** pending requests are shown before terminal requests with student, requested time, quoted price, deadline, loading/empty/error, refresh, and bounded pagination behavior

#### Scenario: Trainer accepts request
- **WHEN** a trainer confirms acceptance of a pending request
- **THEN** the request becomes accepted, the inbox refreshes, and the created Session is available in the sessions UI

#### Scenario: Trainer rejects request
- **WHEN** a trainer selects a required rejection reason and optional comment
- **THEN** the app submits the decision, refreshes the inbox, and does not claim that a Session was created

#### Scenario: Trainer assigns alternate time
- **WHEN** a trainer views linked contacts, confirms external agreement, and submits another valid local date/time
- **THEN** the app shows the final accepted request and resolved Session time without a counter-offer flow

### Requirement: Student can browse linked coach slots and book
The mobile app SHALL let a student see requestable slots of a linked coach and submit a BookingRequest rather than directly create a Session. Russian copy MUST clearly state that the request awaits trainer confirmation.

#### Scenario: Student sends request
- **WHEN** a linked student reviews slot time, mode, and quoted price and taps «Отправить заявку»
- **THEN** the app creates a pending request, shows «Ожидает тренера», and does not claim that the training is confirmed

#### Scenario: Request conflict surfaced
- **WHEN** request creation fails because the slot is held, the student already has a pending request to that coach, or the decision window closed
- **THEN** the app shows a specific Russian conflict message and refreshes requestable availability

#### Scenario: Direct Session booking is unavailable
- **WHEN** a student opens the updated booking flow
- **THEN** no action invokes direct student `POST /sessions`

## ADDED Requirements

### Requirement: Student tracks and withdraws own booking requests
The mobile app SHALL provide a Russian «Мои заявки» experience with pending, accepted, rejected, withdrawn, and expired states, student-visible feedback, resolved time, and a withdraw action only for pending requests.

#### Scenario: Student sees rejection feedback
- **WHEN** the trainer rejects a request with reason/comment
- **THEN** the student's request card shows localized reason and optional comment

#### Scenario: Student withdraws pending request
- **WHEN** the student confirms withdrawal
- **THEN** the app updates the request to withdrawn and refreshes available slots

#### Scenario: Accepted request opens training
- **WHEN** an accepted request contains a Session reference
- **THEN** the student can navigate to the existing sessions destination

### Requirement: Booking request UI handles operational states
Student and trainer BookingRequest screens SHALL use repository-backed Bloc/Cubit and expose loading, empty, success, failure, retry/refresh, submitting, and conflict states without networking inside widgets.

#### Scenario: Inbox load fails
- **WHEN** the request API fails
- **THEN** the app shows a Russian failure state with retry and does not display a false empty state

#### Scenario: Decision is being submitted
- **WHEN** a trainer submits accept/reject/alternate
- **THEN** duplicate actions are disabled until success or failure is returned
