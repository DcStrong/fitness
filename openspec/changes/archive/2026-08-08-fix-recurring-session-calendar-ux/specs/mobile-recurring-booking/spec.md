## MODIFIED Requirements

### Requirement: Trainer reviews series detail and conflicts
The app SHALL show a series detail screen with pattern summary, status, and sync summary (including `slotsCreated` when provided). When the trainer arrives from create with an initial sync summary, the app MUST display that summary without requiring an immediate sync tap. The primary exit control SHALL be «Готово» (return to schedule or list). Horizon materialization SHALL use a secondary control labeled «Обновить горизонт» with Russian copy explaining the series is already active and the action extends/refreshes bookings on the availability horizon. Conflict reasons MUST be localized. For each resolvable conflict the trainer MUST be able to skip the date (reschedule UI may remain deferred). Cancel series MUST require confirmation. Cancelled detail MUST NOT prompt to sync and MUST offer permanent delete.

#### Scenario: After create detail shows sync summary and Done
- **WHEN** create returns a sync summary and detail opens
- **THEN** the UI shows booked/slotsCreated/conflicts counts and a «Готово» action without requiring «Синхронизировать»

#### Scenario: Update horizon
- **WHEN** a trainer taps «Обновить горизонт» on an active series
- **THEN** the app calls sync and refreshes the summary

#### Scenario: Cancel series
- **WHEN** a trainer confirms cancellation of an active series
- **THEN** the app cancels via API and the series leaves the active list (archive/cancelled)

#### Scenario: Delete cancelled series
- **WHEN** a trainer deletes a cancelled series from detail
- **THEN** the app calls delete and returns to the list without that series

## ADDED Requirements

### Requirement: Active list and cancelled archive
The recurring list SHALL show active series by default and SHALL provide access to cancelled (archive) series without restore. Archive entries MAY be opened and permanently deleted.

#### Scenario: Active list hides cancelled
- **WHEN** the trainer opens the recurring list
- **THEN** cancelled series are not shown in the primary active list
