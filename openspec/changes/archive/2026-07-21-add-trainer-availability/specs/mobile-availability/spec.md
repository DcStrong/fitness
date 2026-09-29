## ADDED Requirements

### Requirement: Trainer edits availability settings in Russian UI
The mobile app SHALL provide a Russian «Настройки графика» section on the trainer «Доступность» tab for duration minutes, optional break minutes, generation horizon, and related schedule settings using `FyInputCard` fields and `FyButton` actions. Saving MUST go through a repository-backed Cubit and expose loading, saving, success and failure states without networking inside widgets.

#### Scenario: Trainer saves duration and break
- **WHEN** a trainer enters valid duration and break values and confirms save
- **THEN** the app persists settings through the API and shows an updated success state

#### Scenario: Invalid settings surfaced
- **WHEN** save fails validation or the API rejects the payload
- **THEN** the app shows a Russian error state and keeps the editor usable for correction

### Requirement: Trainer manages weekly working windows
The «Доступность» editor SHALL show a «Рабочая неделя» day-of-week picker (Monday-first chips), the list of time windows for the selected day with clock affordance and delete, actions «+ Добавить часы» and «Скопировать на Пн–Пт», and persist the weekly template through the schedules availability API. The day-of-week picker MAY be a new shared widget because no existing one is present.

#### Scenario: Trainer adds a window to Tuesday
- **WHEN** a trainer selects Tuesday, adds a time window and saves the template
- **THEN** the window appears for Tuesday on reload and is stored on the backend template

#### Scenario: Copy to weekdays
- **WHEN** a trainer taps «Скопировать на Пн–Пт» with windows defined for the source day
- **THEN** Monday through Friday receive the same window set in the editor state ready to save

### Requirement: Trainer manages exceptions and previews generated slots
The editor SHALL include an «Исключения» section for closed days or custom hours on specific dates and a preview of slots implied by the fixed grid for the current settings and template. Generating availability MUST call the backend generate operation, then refresh preview/calendar-relevant slot data. UI MUST follow the Fitness Yoda concept `docs/assets/fitness-yoda-availability-fixed-grid-v1.png` and reuse `FyCard` / `FyButton` / `FyInputCard` (and `CalendarDateStrip` where date picking fits).

#### Scenario: Trainer marks a day closed
- **WHEN** a trainer adds a closed-day exception and saves
- **THEN** that date is listed under exceptions and subsequent generation omits template windows for it

#### Scenario: Trainer generates availability
- **WHEN** a trainer confirms generate after saving settings and template
- **THEN** the app reports generation completion and shows materialized slots in preview or via refreshed schedule data

#### Scenario: Operational states
- **WHEN** template load, save or generate fails
- **THEN** the app shows a Russian failure state with retry and does not present a false empty success template
