## ADDED Requirements

### Requirement: Trainer can bulk-update working weights on a plan without replacing the exercise list
The system SHALL allow the owning coach with `plans:update_own` to PATCH working weights on a `kind=template` or `kind=student_copy` plan by `exerciseId`. Each listed `weight_reps` exercise MUST receive the given `weightKg` on all of its sets. The exercise order, reps, rest, and duration fields MUST remain unchanged. Unknown `exerciseId` values or foreign plans MUST be rejected. Catalog seed plans MUST NOT accept this PATCH.

#### Scenario: Update bench weight on template
- **WHEN** the owner PATCHes loads with bench press 80 kg on their template
- **THEN** every set of that exercise on the template stores 80 kg and other exercises are unchanged

#### Scenario: Student copy loads do not change template
- **WHEN** the owner PATCHes loads on a student copy
- **THEN** the parent template weights stay the same

#### Scenario: Catalog loads rejected
- **WHEN** a user PATCHes loads on a `kind=catalog_seed` plan
- **THEN** the system rejects the request
