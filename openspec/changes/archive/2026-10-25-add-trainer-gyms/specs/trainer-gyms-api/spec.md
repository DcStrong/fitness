## ADDED Requirements

### Requirement: Trainer manages own gyms
The system SHALL let a user with the trainer role and `profiles:update_own` attach gyms to their profile, list their own gyms, and detach them. A gym consists of a name, an exact address, a city, and an optional free-text district. Non-trainers MUST receive 403. A trainer MAY attach at most 10 gyms; exceeding the limit MUST return 409.

#### Scenario: Trainer enters a new gym
- **WHEN** a trainer submits name, address, and city that match no existing gym
- **THEN** a gym record is created, attached to the trainer, and returned with its id

#### Scenario: Trainer detaches a gym
- **WHEN** a trainer deletes the attachment of a gym attached to their profile
- **THEN** the response is 204 and the gym no longer appears in their list, while the gym record remains for other trainers

#### Scenario: Detaching a gym that is not attached
- **WHEN** a trainer deletes an attachment that does not exist for them
- **THEN** the response is 404

### Requirement: Gyms are deduplicated across trainers
The system SHALL keep one gym record per normalized (name, address, city) key, ignoring letter case, `ё`/`е`, and repeated whitespace. A trainer entering an equivalent gym MUST be attached to the existing record. Concurrent submissions MUST NOT create duplicates. A missing district on the existing record MAY be filled by a later submission, but an existing district MUST NOT be overwritten.

#### Scenario: Two trainers enter the same gym
- **WHEN** two trainers submit the same gym with different letter case or spacing
- **THEN** both are attached to the same gym id and only one record exists

#### Scenario: Attach by identifier is idempotent
- **WHEN** a trainer attaches an already attached gym by `gymId`
- **THEN** the call succeeds and no duplicate attachment is created

### Requirement: Gym suggestions come from trainer input
The system SHALL expose gym suggestions to trainers, filtered by a substring of the gym name or address and by city, ordered by name, with a limit of at most 20. There is no pre-populated catalog. Suggestions MUST NOT reveal which trainers use a gym. Wildcard characters in the query MUST be matched literally.

#### Scenario: Suggestion by name substring
- **WHEN** a trainer requests suggestions with a substring of an existing gym name
- **THEN** the matching gym is returned without any trainer information

#### Scenario: Student requests suggestions
- **WHEN** a student requests suggestions
- **THEN** the response is 403
