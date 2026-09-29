## MODIFIED Requirements

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
