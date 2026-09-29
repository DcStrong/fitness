## ADDED Requirements

### Requirement: Session can reference an assigned student workout
The system SHALL store optional `studentPlanId` on a Session. GET session responses for participants MUST include the id and, when loaded, a summary of the linked plan (title, goal, tags, exercises). A user with `sessions:book_for_student` who is the session coach MAY PATCH `studentPlanId` to a `kind=student_copy` owned by that coach and assigned to the session student, or to null to detach. Foreign or template-kind ids without a matching copy MUST be rejected.

#### Scenario: Attach copy to session
- **WHEN** the coach PATCHes a booked session with a student copy for that student
- **THEN** subsequent GET returns that `studentPlanId` and plan summary

#### Scenario: Wrong student's copy rejected
- **WHEN** the coach attaches a copy assigned to a different student
- **THEN** the system rejects the request

#### Scenario: Detach
- **WHEN** the coach PATCHes `studentPlanId` null
- **THEN** the session has no linked plan and lifecycle remains available

#### Scenario: Student cannot attach
- **WHEN** the student PATCHes `studentPlanId`
- **THEN** the system rejects the request
