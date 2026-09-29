## MODIFIED Requirements

### Requirement: Trainer can manage schedule and book for student in app
The mobile app SHALL provide a Russian trainer workspace with «Календарь», «Заявки» and «Доступность» contexts. The calendar SHALL combine the trainer's availability and scheduled training records, SHALL support day/week/month views, and SHALL allow the trainer to create one-off free time and continue to book a linked student through the applicable booking flow.

#### Scenario: Trainer opens schedule management
- **WHEN** an authenticated trainer opens «Расписание»
- **THEN** the app shows the calendar workspace inside the existing trainer shell rather than the legacy «Мои слоты» list

#### Scenario: Trainer adds free time
- **WHEN** a trainer submits a valid one-off availability form from «Свободное время»
- **THEN** the new open slot appears in the calendar's applicable day, week and month projections

#### Scenario: Trainer books linked student
- **WHEN** a trainer selects a free slot and a linked student and confirms
- **THEN** the app creates a booked session and refreshes that time from free availability to a training event

#### Scenario: Trainer opens requests
- **WHEN** a trainer selects the «Заявки» context
- **THEN** the app opens the trainer request inbox supplied by the booking-requests capability without adding a new bottom-navigation destination

#### Scenario: Pending inbox actions match concept order and density
- **WHEN** a pending booking request card is shown in the schedule «Заявки» inbox
- **THEN** actions appear in order «Принять», «Другое время», «Отклонить» with filled primary, outlined primary and outlined error styling respectively, and use compact control height rather than the tall auth CTA minimum

#### Scenario: Trainer opens availability
- **WHEN** a trainer selects the «Доступность» context before recurring availability is available
- **THEN** the app retains access to manual one-off availability management without presenting unsupported recurrence controls
