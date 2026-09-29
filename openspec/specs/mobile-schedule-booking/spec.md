# mobile-schedule-booking Specification

## Purpose
Flutter UI for trainer calendar workspace («Календарь / Заявки / Доступность»), student booking requests, coach book-for-student via mobile-coach-booking, recurring entry from create actions, and sessions list (Russian copy).
## Requirements
### Requirement: Trainer can manage schedule and book for student in app
The mobile app SHALL provide a Russian trainer workspace with «Календарь», «Заявки» and «Доступность» contexts. The calendar SHALL combine the trainer's availability and scheduled training records, SHALL support day/week/month views, and SHALL allow the trainer to create one-off free time and to book a linked student from an open slot or from an arbitrary free time via the mobile-coach-booking flow. The «Доступность» context SHALL open the weekly availability editor (settings, working week, exceptions, preview/generate) supplied by the mobile-availability capability rather than a flat one-off slot CRUD list. One-off availability creation MUST remain available from the calendar create-actions «Свободное время» entry. Legacy «Мои слоты» MUST NOT be the primary trainer path.

#### Scenario: Trainer opens schedule management
- **WHEN** an authenticated trainer opens «Расписание»
- **THEN** the app shows the calendar workspace inside the existing trainer shell rather than the legacy «Мои слоты» list

#### Scenario: Trainer adds free time
- **WHEN** a trainer submits a valid one-off availability form from «Свободное время»
- **THEN** the new open slot appears in the calendar's applicable day, week and month projections

#### Scenario: Trainer books linked student from free slot
- **WHEN** a trainer selects a free slot and a linked student and confirms
- **THEN** the app creates a booked session and refreshes that time from free availability to a training event

#### Scenario: Trainer books linked student without prior slot
- **WHEN** a trainer books a linked student at a free interval with no open slot
- **THEN** the app uses book-at-time and shows the new training after refresh

#### Scenario: Trainer opens requests
- **WHEN** a trainer selects the «Заявки» context
- **THEN** the app opens the trainer request inbox supplied by the booking-requests capability without adding a new bottom-navigation destination

#### Scenario: Pending inbox actions match concept order and density
- **WHEN** a pending booking request card is shown in the schedule «Заявки» inbox
- **THEN** actions appear in order «Принять», «Другое время», «Отклонить» with filled primary, outlined primary and outlined error styling respectively, and use compact control height rather than the tall auth CTA minimum

#### Scenario: Trainer opens availability
- **WHEN** a trainer selects the «Доступность» context
- **THEN** the app shows the availability editor for schedule settings, weekly windows, exceptions and generation instead of the legacy flat slots CRUD list

#### Scenario: One-off free time remains outside availability editor
- **WHEN** a trainer needs a single extra open interval outside the weekly template
- **THEN** the trainer uses «Свободное время» from the calendar create actions rather than the availability template editor

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
The mobile app SHALL let a student see requestable slots of a linked coach and submit a BookingRequest rather than directly create a Session. The list MUST NOT present a send action for slots whose decision window is already closed. Russian copy MUST clearly state that the request awaits trainer confirmation and MUST explain that a request can be sent no later than two hours before the slot starts.

#### Scenario: Student sends request
- **WHEN** a linked student reviews slot time, mode, and quoted price and taps «Отправить заявку»
- **THEN** the app creates a pending request, shows «Ожидает тренера», and does not claim that the training is confirmed

#### Scenario: Requestable list omits closed-window slots
- **WHEN** a linked student opens «Запись к тренеру» and the coach has open slots that start within two hours or have already started
- **THEN** those slots are not shown as sendable; if nothing remains, the empty state explains that booking closes two hours before start

#### Scenario: Request conflict surfaced
- **WHEN** request creation fails because the slot is held, the student already has a pending request to that coach, or the decision window closed
- **THEN** the app shows a specific Russian conflict message (for a closed create window: that a request must be sent at least two hours before start) and refreshes requestable availability

#### Scenario: Direct Session booking is unavailable
- **WHEN** a student opens the updated booking flow
- **THEN** no action invokes direct student `POST /sessions`

### Requirement: Both roles can see upcoming sessions list
The app SHALL show a simple list of the current user's sessions (time, counterpart email/id, status).

#### Scenario: Home or sessions screen shows bookings
- **WHEN** an authenticated user opens the sessions list
- **THEN** their booked sessions are displayed

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

### Requirement: Trainer can open recurring booking from schedule workspace
The mobile schedule workspace SHALL expose a Russian entry point labelled for student recurring trainings (e.g. «Регулярные тренировки») via the calendar create-actions sheet, without a new bottom-navigation destination and without implying trainer weekly availability. One-off «Свободное время», BookingRequest inbox actions, and direct book-for-student MUST remain available alongside recurring flows.

#### Scenario: Entry does not replace one-off booking
- **WHEN** a trainer opens the schedule workspace
- **THEN** the trainer can still perform one-off free-time creation and one-off student booking in addition to opening the recurring trainings flow

#### Scenario: Recurring entry from create sheet
- **WHEN** a trainer chooses «Регулярные тренировки» from the calendar create actions
- **THEN** the app opens the mobile-recurring-booking list or create flow

### Requirement: Session history back respects navigation stack
The session history screen SHALL pop the navigation stack when possible so returning from a calendar-opened history lands on the schedule calendar. Only when the stack cannot pop MAY it navigate to `/sessions`.

#### Scenario: Back from calendar-opened history
- **WHEN** a trainer opens history from the calendar manage flow and presses Back
- **THEN** the app returns to the previous screen (schedule) rather than forcing «Мои тренировки»

### Requirement: Alternate-time picker shows monthly occupancy calendar
When a trainer chooses «Другое время» / alternate resolution for a pending booking request, the date/time selection UI SHALL present a month grid of the trainer's calendar occupancy (same event types as calendar «Месяц»: trainings, free slots, pending requests), allow selecting a day to inspect that day's occupancy, then confirm a local time. The flow MUST NOT rely on a bare date-only picker without occupancy context. Data MUST come from existing calendar/schedule sources without a new backend endpoint.

#### Scenario: Trainer opens alternate date picker
- **WHEN** a trainer starts choosing an alternate date and time for a pending request
- **THEN** the app shows a monthly occupancy calendar rather than only a plain calendar date picker without busy markers

#### Scenario: Trainer inspects a day's occupancy
- **WHEN** the trainer selects a day on the month grid
- **THEN** the app shows that day's occupied intervals so the trainer can pick a free time knowingly

#### Scenario: Trainer confirms alternate local datetime
- **WHEN** the trainer selects a day, chooses a local time, and confirms
- **THEN** the alternate flow receives that local DateTime for submission through the existing alternate API

