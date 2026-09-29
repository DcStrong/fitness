## MODIFIED Requirements

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

### Requirement: Trainer can open recurring booking from schedule workspace
The mobile schedule workspace SHALL expose a Russian entry point labelled for student recurring trainings (e.g. «Регулярные тренировки») via the calendar create-actions sheet, without a new bottom-navigation destination and without implying trainer weekly availability. One-off «Свободное время», BookingRequest inbox actions, and direct book-for-student MUST remain available alongside recurring flows.

#### Scenario: Entry does not replace one-off booking
- **WHEN** a trainer opens the schedule workspace
- **THEN** the trainer can still perform one-off free-time creation and one-off student booking in addition to opening the recurring trainings flow

#### Scenario: Recurring entry from create sheet
- **WHEN** a trainer chooses «Регулярные тренировки» from the calendar create actions
- **THEN** the app opens the mobile-recurring-booking list or create flow
