## ADDED Requirements

### Requirement: Calendar session opens manage actions
When a trainer taps a non-cancelled session event on the calendar, the app SHALL present manage actions for that occurrence: mark completed, cancel, mark no-show (when permitted), and open history — instead of navigating only to history.

#### Scenario: Tap booked session
- **WHEN** a trainer taps a booked session on the calendar
- **THEN** a manage sheet/actions UI appears with status actions and history entry

### Requirement: Cancelled sessions do not block calendar availability display
The calendar event map SHALL omit sessions with status `cancelled` so that a released open slot at the same interval can appear as availability.

#### Scenario: Cancelled session omitted
- **WHEN** calendar events are mapped and a session is `cancelled`
- **THEN** that session is not shown as a calendar event
