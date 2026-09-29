## ADDED Requirements

### Requirement: Session history back respects navigation stack
The session history screen SHALL pop the navigation stack when possible so returning from a calendar-opened history lands on the schedule calendar. Only when the stack cannot pop MAY it navigate to `/sessions`.

#### Scenario: Back from calendar-opened history
- **WHEN** a trainer opens history from the calendar manage flow and presses Back
- **THEN** the app returns to the previous screen (schedule) rather than forcing «Мои тренировки»
