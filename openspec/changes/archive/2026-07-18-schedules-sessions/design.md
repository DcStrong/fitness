## Context

Phases 1–3: auth, mobile shell, QR coach–student links.  
Phase 4 makes **calendar/booking** the product core. We need a backend design that stays simple in MVP but does not paint the domain into a corner. Canonical write-up: [docs/architecture/calendar.md](../../../docs/architecture/calendar.md).

Delivery: **architecture doc → backend → Flutter**. Web out of scope.

## Goals / Non-Goals

**Goals:**
- Separate **availability (ScheduleSlot)** from **appointments (Session)**.
- Enforce time invariants, link checks, transactional booking (no double-book).
- MVP: create open slots, book 1:1 → `session.status=booked`, list sessions.
- Schema/API ready for lifecycle, recurrence, gym, groups later.
- Thin Flutter UI on top.

**Non-Goals (MVP):**
- complete/cancel/no_show UI/API transitions (enum values may exist).
- recurrence generator UI, groups, gym required, notifications, invoices, plans.

## Decisions

### 1. Availability vs Session (foundational)
- **ScheduleSlot** = bookable capacity inventory (`open` → `booked`).
- **Session** = canonical appointment with snapshot `startsAt`/`endsAt` copied from slot at book time.
- Rationale: future history/invoices/plans hang off Session; free-time UI hangs off Slot.
- Rejected: single-table “events” mixing free and busy without clear types.

### 2. MVP schema (with extension hooks)
**schedule_slots**
- `id`, `coach_id`, `starts_at`, `ends_at` (`timestamptz`), `mode` (`online`|`offline`)
- `status` (`open`|`booked`) — CHECK allows future `blocked`
- nullable hooks: `series_id`, `gym_id`, `capacity` default `1`
- `created_at`, `updated_at`
- indexes: `(coach_id, starts_at)`; unique booking via sessions

**sessions**
- `id`, `coach_id`, `student_id` (1:1 MVP), `schedule_slot_id` **NOT NULL** unique
- snapshot `starts_at`, `ends_at`, `mode`
- `status` CHECK including `booked|completed|cancelled|no_show` (write path only `booked`)
- `created_by` (`coach`|`student`)
- timestamps

Future: `session_participants` replaces `student_id`; `schedule_series` generates slots.

### 3. Invariants (must implement in services)
1. `ends_at > starts_at`
2. Coach open slots must not overlap (`[start,end)`).
3. Book only if slot `open`, owned correctly, and coach–student link exists.
4. Book in **DB transaction**: lock slot → insert session → set slot `booked`.
5. Client cannot override slot times on book — server copies from slot.

### 4. Nest module layout
- `schedules` module — availability use-cases
- `sessions` module — booking + list
- Shared booking rules in a dedicated service (e.g. `CalendarBookingService`) used by sessions
- Controllers thin; permissions via existing guards

### 5. API (MVP)
- `POST /schedule/slots`, `GET /schedule/slots?from&to`, `DELETE /schedule/slots/:id` (only `open`)
- `GET /schedule/coaches/:coachId/slots?from&to` (linked; only `open`)
- `POST /sessions` `{ scheduleSlotId, studentId? }`
- `GET /sessions?from&to`
- Responses ISO-8601 timestamptz

### 6. Permissions (seed)
| Code | trainer | student |
|------|---------|---------|
| `schedules:create` | ✓ | |
| `schedules:read_own` | ✓ | |
| `schedules:delete_own` | ✓ | |
| `schedules:read_linked` | | ✓ |
| `sessions:book_self` | | ✓ |
| `sessions:book_for_student` | ✓ | |
| `sessions:read_own` | ✓ | ✓ |

### 7. Mobile (after API)
- Trainer: manage slots; book for linked student
- Student: list linked coach open slots; book
- Both: sessions list
- RU copy; Material 3

### 8. Implementation order
1. Write/confirm `docs/architecture/calendar.md` (done in propose; keep in sync on apply)
2. Migration + entities reflecting hooks + status CHECKs
3. Domain booking service + schedules/sessions API + Postman + smoke
4. Flutter thin client
5. Manual two-client smoke

## Risks / Trade-offs

- [Overlap only in app code] → acceptable MVP; document gist EXCLUDE as follow-up hardening.
- [No recurrence yet] → explicit slots only; `series_id` nullable avoids rewrite.
- [1:1 `student_id`] → groups need participants migration later; documented path.
- [Lifecycle unused statuses] → CHECK includes them so phase 5 does not reshape enum painfully.
- [Timezone bugs] → timestamptz only; no naive timestamps.

## Migration Plan

1. Add `schedule_slots`, `sessions` with constraints/indexes.
2. Seed new permissions onto trainer/student (re-login for JWT).
3. Ship API then Flutter.
4. Rollback: disable modules; tables inert.

## Open Questions

1. PostgreSQL `EXCLUDE` gist in this change or immediate follow-up? **Default: app overlap + unique slot booking now; gist optional stretch.**
2. Soft-delete slots vs status `blocked`? **Delete only if `open`; else forbid.**
3. Ad-hoc session without slot? **Out of MVP** (keeps one booking path).
4. Cancel window hours — phase 5.
