## Context

Phase 4 delivered ScheduleSlot + Session booking (`booked` only). Phase 5 adds **lifecycle transitions** and **history events** so appointments become a durable product fact (complete / cancel / no_show) without inventing invoices or notifications yet.

Canonical model: [docs/architecture/calendar.md](../../../docs/architecture/calendar.md). Types already live under `sessions/interface/` (`SessionStatus` includes terminal states).

Delivery: **backend → Flutter**; web out of scope.

## Goals / Non-Goals

**Goals:**
- Enforce allowed transitions: `booked → completed | cancelled | no_show` (no reverse; no terminal→terminal).
- Persist an append-only **history event** per successful transition (actor, timestamps, from/to, optional note).
- Permission-gated APIs + thin Flutter actions on sessions list/detail.
- Keep domain interfaces in `src/<domain>/interface/` (no types on entities).

**Non-Goals:**
- Auto-reopen ScheduleSlot on cancel (MVP: slot stays `booked`; document as policy).
- Reschedule endpoint, refunds, invoices, push.
- Soft-delete sessions; editing/deleting history rows.
- Groups / participants table.

## Decisions

### 1. Transition API shape
- Prefer explicit endpoints (clear permissions & audit):
  - `POST /sessions/:id/complete`
  - `POST /sessions/:id/cancel` body `{ note?: string }`
  - `POST /sessions/:id/no-show`
- Rejected: single `PATCH /sessions/:id { status }` (too easy to smuggle illegal transitions).

### 2. Who may do what (MVP)
| Action | Trainer (coach of session) | Student (student of session) |
|--------|----------------------------|------------------------------|
| complete | ✓ | ✗ |
| cancel | ✓ | ✓ |
| no_show | ✓ | ✗ |

Permissions (seed):
- `sessions:complete` → trainer
- `sessions:cancel` → trainer + student
- `sessions:mark_no_show` → trainer
- `sessions:read_history` → trainer + student

Service still checks **participant membership** (caller is coachId or studentId) in addition to permission.

### 3. History storage
Table `session_history_events`:
- `id`, `session_id`, `actor_user_id`, `from_status`, `to_status`, `note` nullable, `created_at`
- Append-only; written in the **same DB transaction** as the session status update.
- Optional: also write a `booked` event at booking time in a follow-up; **this change** may only log transitions out of `booked` (simpler). Prefer logging transition events for complete/cancel/no_show; booking remains implied by session.createdAt.

### 4. Slot policy on cancel
- **Do not** auto-set ScheduleSlot back to `open` in MVP (avoids double-book edge cases with unique `schedule_slot_id` still pointing at cancelled session).
- Future: cancel → free slot OR allow new session on same slot via partial unique index — out of scope.

### 5. List filters
- Extend `GET /sessions?status=` optional (comma or single) so mobile can show «предстоящие» vs «история».
- `GET /sessions/:id/history` for event timeline.

### 6. Module layout
- Keep logic in `sessions` module (+ `SessionHistoryEvent` entity under `database/entity`).
- Domain types in `sessions/interface/` (transition params/returns, history model).
- Optional small `SessionLifecycleService` for transition + history write.

### 7. Mobile
- Sessions list: show status; for `booked` show actions by role.
- History: bottom sheet or `/sessions/:id/history` screen (RU).
- Reuse existing `ScheduleRepository` or split `SessionsRepository` — prefer clear sessions API client methods.

## Risks / Trade-offs

- [Cancelled session blocks slot forever] → Mitigation: document; later migration for reopen or replace unique constraint.
- [Student cancels late] → Mitigation: no time-window rules in MVP; add later.
- [OR permissions vs guard AND] → Mitigation: same pattern as book — check capability in service if endpoint needs OR; prefer one permission per endpoint.
- [Missing history on old booked sessions] → Acceptable; events start from first transition.

## Migration Plan

1. Migration: `session_history_events` + indexes `(session_id, created_at)`.
2. Seed new permissions / role links.
3. Deploy API; clients must re-login for JWT permission claims.
4. Flutter after API smoke.
5. Rollback: drop endpoints unused; table can remain empty.

## Open Questions

- None blocking: slot-reopen deferred; booking-time history event deferred.
