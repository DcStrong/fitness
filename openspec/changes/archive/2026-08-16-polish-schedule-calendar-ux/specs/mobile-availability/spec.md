## ADDED Requirements

### Requirement: Availability fields expose Russian help copy
The «Доступность» editor SHALL show a help affordance (question-mark-in-circle) next to each settings and section label that needs explanation — at least duration, break, generation horizon, working windows, and exceptions. Activating help MUST present Russian text describing what the field means and why the trainer fills it. Networking MUST NOT run from the help UI.

#### Scenario: Trainer opens horizon help
- **WHEN** a trainer activates help next to «Горизонт генерации»
- **THEN** the app shows Russian copy explaining that the horizon is how many weeks ahead open slots are generated from the weekly template

#### Scenario: Trainer opens duration help
- **WHEN** a trainer activates help next to the default duration field
- **THEN** the app shows Russian copy explaining that duration is the length of each generated training slot

## MODIFIED Requirements

### Requirement: Trainer manages weekly working windows
The «Доступность» editor SHALL show a «Рабочая неделя» day-of-week picker (Monday-first chips), the list of time windows for the selected day with clock affordance and delete, actions «+ Добавить часы» and «Скопировать на каждый день», and persist the weekly template through the schedules availability API. The day-of-week picker MAY be a new shared widget because no existing one is present. After a successful copy into editor state the app MUST show a Russian SnackBar (or equivalent transient success notice) confirming the action.

#### Scenario: Trainer adds a window to Tuesday
- **WHEN** a trainer selects Tuesday, adds a time window and saves the template
- **THEN** the window appears for Tuesday on reload and is stored on the backend template

#### Scenario: Copy to weekdays
- **WHEN** a trainer taps «Скопировать на каждый день» with windows defined for the source day
- **THEN** Monday through Sunday receive the same window set in the editor state ready to save

#### Scenario: Copy shows success feedback
- **WHEN** a trainer completes «Скопировать на каждый день»
- **THEN** the app shows a transient Russian success notice that the windows were copied to every day
