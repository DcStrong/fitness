## ADDED Requirements

### Requirement: One conversation per coach–student pair
The system SHALL keep at most one chat conversation per (coach, student) pair. Creating a conversation for a pair that already has one MUST return the existing conversation. A conversation MAY be created only when an active coach–student link exists for the pair.

#### Scenario: Get-or-create is idempotent
- **WHEN** a linked trainer requests a conversation with the same student twice
- **THEN** both calls return the same conversation id

#### Scenario: Unlinked pair is refused
- **WHEN** a user requests a conversation with a user they have no coach–student link with
- **THEN** the request is rejected with 403 and no conversation is created

### Requirement: Only participants can read a conversation
The system SHALL return conversation data and messages only to its two participants, gated by `chat:read_own`. A non-participant MUST receive 404.

#### Scenario: Stranger reads a conversation
- **WHEN** an authenticated user who is not a participant requests messages of a conversation
- **THEN** the response is 404

### Requirement: Participants send text messages idempotently
A participant with `chat:send_own` and an active link SHALL be able to send a text message of 1–4000 characters after trimming. Each send carries a client-generated `clientId`; repeating a send with the same `clientId` in the same conversation MUST return the originally stored message and MUST NOT create a duplicate.

#### Scenario: Retry after network error
- **WHEN** the app resends a message with a `clientId` that was already stored
- **THEN** the API returns the stored message and the conversation contains it once

#### Scenario: Empty message
- **WHEN** a participant sends a body that is empty after trimming
- **THEN** the request is rejected with 400

### Requirement: Messages are paged by cursor
The system SHALL return messages ordered by creation time with cursor parameters `before` and `after` (message ids) and a `limit` of at most 100. A request with `after` MUST return only messages newer than the cursor, so clients can poll for new messages.

#### Scenario: Poll with no new messages
- **WHEN** a participant requests messages `after` the latest message id
- **THEN** the response is an empty list

### Requirement: Unread counts per participant
The system SHALL track a last-read moment per participant and report, per conversation and in total, the number of messages newer than it that were not sent by the caller (system messages included). Marking as read MUST only move the moment forward.

#### Scenario: Incoming message raises unread
- **WHEN** a student sends a message to their coach
- **THEN** the coach's conversation list shows unread 1 for that conversation and total unread increases by 1

#### Scenario: Reading clears unread
- **WHEN** the coach marks the conversation read up to the latest message
- **THEN** the coach's unread count for it becomes 0

### Requirement: Session events appear as system messages
When a coach books a session for a student, a session is cancelled, a recurring occurrence is rescheduled or skipped, or a booking request is accepted, answered with an alternate time, or rejected, the system SHALL append a system message to the pair's conversation (creating it when missing) in the same transaction as the event. The message MUST carry `system_type` and a payload with the session id and times when applicable, plus a Russian fallback body.

#### Scenario: Coach cancels a session
- **WHEN** a coach cancels a booked session with a note
- **THEN** the pair's conversation gains a `session_cancelled` system message with the session id and note

#### Scenario: Event transaction fails
- **WHEN** the underlying session operation fails and rolls back
- **THEN** no system message is stored
