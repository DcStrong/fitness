## ADDED Requirements

### Requirement: Cancel series releases future slots
When a coach cancels an active RecurringBooking, the system SHALL cancel future `booked` Sessions of that series AND set each linked ScheduleSlot status to `open` so the time becomes bookable again. Completed, cancelled, and no-show Sessions MUST NOT be reversed. A normal one-off session cancel without `releaseSlot` MAY leave the slot booked.

#### Scenario: Cancel frees matching slots
- **WHEN** a coach cancels an active series that has future booked Sessions on slots
- **THEN** those Sessions become `cancelled` and their ScheduleSlots become `open`

### Requirement: List recurring bookings by status
`GET /recurring-bookings` SHALL accept optional `status=active|cancelled|all` and MUST default to `active` when omitted.

#### Scenario: Default list is active only
- **WHEN** a coach lists recurring bookings without a status query
- **THEN** only `active` series are returned

#### Scenario: Archive list
- **WHEN** a coach lists with `status=cancelled`
- **THEN** only cancelled series are returned

### Requirement: Hard delete cancelled series
The system SHALL allow the owning coach to `DELETE` a RecurringBooking only when its status is `cancelled`. Active series MUST be rejected. Delete MUST remove the series and its occurrence overrides.

#### Scenario: Delete cancelled series
- **WHEN** a coach deletes a cancelled series
- **THEN** the series is removed and subsequent GET returns not found

#### Scenario: Delete active rejected
- **WHEN** a coach attempts to delete an active series
- **THEN** the system rejects the request
