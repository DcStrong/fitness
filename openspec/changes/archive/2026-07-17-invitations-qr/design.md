## Context

Phases 1–2 delivered Nest auth (TypeORM, JWT, permissions) and Flutter auth shell (Bloc, go_router, dio). Phase 3 connects trainer and student via QR invitations per `docs/domain/invitations.md`. Delivery order remains **backend first, then Flutter**. Web is out of scope.

## Goals / Non-Goals

**Goals:**
- Persist invitations and create coach–student links on accept.
- Permission-gated REST API for create/list/revoke/accept + read relationships.
- Minimal Flutter UX: trainer QR + copy link; student deep link / accept flow with Russian UI.
- Fix placeholder deep link scheme/host for later production hardening.

**Non-Goals:**
- NFC/barcode, push, email, web console.
- Silent auto-register from QR without auth screens.
- Universal Links / App Links verification with real domains.
- Groups, sessions, billing.

## Decisions

### 1. Data model
- **Invitation**: `id`, `coachId` (FK user), `tokenHash` (unique), `status` (`pending` | `accepted` | `revoked` | `expired`), `expiresAt`, `acceptedByUserId?`, timestamps.
- Store **hash of token** server-side; return raw token once on create for QR/URL.
- **CoachStudentLink** (or `coach_students`): `id`, `coachId`, `studentId`, unique `(coachId, studentId)`, `createdAt`, optional `sourceInvitationId`.
- Alternatives considered: embed students array on coach profile — rejected (harder queries, weaker integrity).

### 2. Token & URL shape
- Opaque random token (e.g. 32+ bytes hex/base64url).
- Deep link placeholders (roadmap open question #2):
  - App scheme: `fitnessyoda://invite/<token>`
  - HTTPS fallback (for QR readability / future App Links): `https://app.fitness-yoda.local/i/<token>`
- QR encodes the **HTTPS fallback URL** by default (easier camera apps); app also handles custom scheme when opened from OS.
- Alternatives: signed JWT in QR with client-side verify — rejected for MVP; server remains source of truth on accept.

### 3. API surface (Nest module `invitations`)
Suggested endpoints (names flexible at apply):
- `POST /invitations` — create (trainer)
- `GET /invitations` — list own (trainer)
- `POST /invitations/:id/revoke` — revoke (trainer)
- `POST /invitations/accept` `{ token }` — accept (student)
- `GET /relationships/me` — list links for current user

TTL default: e.g. 7 days via config/env. Mark expired either lazily on read/accept or via status check comparing `expiresAt`.

### 4. Permissions (seed)
| Code | trainer | student |
|------|---------|---------|
| `invitations:create` | ✓ | |
| `invitations:read_own` | ✓ | |
| `invitations:revoke` | ✓ | |
| `invitations:accept` | | ✓ |
| `relationships:read_own` | ✓ | ✓ |

Guards remain permission-based (`access-control` pattern).

### 5. Accept rules
- Caller ≠ coach.
- Status must be `pending` and `expiresAt > now`.
- Prefer requiring student role/permission; if user is trainer-only, reject accept (keeps MVP simple; multi-role later).
- On success: set invitation accepted + upsert link.

### 6. Mobile architecture
- Feature folder `lib/features/invitations/` (data + cubit + screens) per `flutter-bloc-feature`.
- Packages: QR render (`qr_flutter` or equivalent), clipboard (`services`/`Clipboard`), optional scanner later (`mobile_scanner`) — for MVP **display QR + paste/open link** is enough; camera scan can be phase stretch if time allows.
- Deep links: `go_router` path `/invite/accept?token=` + platform deep link config stubs documenting placeholders.
- Pending token: hold in memory / secure-ish prefs until after login.
- Home: extend to call `GET /relationships/me` and show stub Russian text.

### 7. Implementation order
1. Migration + entities + permissions seed  
2. Invitations + relationships API + Postman/smoke  
3. Flutter repository/cubit/screens + router  
4. Manual smoke: trainer create → student accept → both see link  

## Risks / Trade-offs

- [Placeholder deep links don't open from all QR scanners] → Prefer HTTPS URL in QR; document scheme for in-app/testing.
- [Token leakage if logged] → Never log raw tokens; hash at rest.
- [Trainer accepting own invite / duplicate spam] → Explicit reject own accept; unique coach–student constraint.
- [Desktop/macOS camera scan weak] → MVP focuses on copy link + manual token/open URL; QR display still useful for phone testing.
- [Stale seed on existing DBs] → Provide migration + seed update instructions; document re-seed or insert permissions.

## Migration Plan

1. Add TypeORM migration for `invitations` + `coach_student_links` (+ indexes).
2. Extend seed permissions/role links.
3. Deploy/restart API; run migration.
4. Ship Flutter build with new routes.
5. Rollback: drop feature module usage; tables can remain unused (no destructive rollback required for MVP).

## Open Questions

1. Final production domain / Universal Links — deferred; placeholders fixed above.
2. Should a user with both roles accept invites? MVP: accept permission only on `student` bundle.
3. Camera QR scan in this change vs create+copy only? Default: **QR display + copy link + deep link accept**; add scanner if low-cost during apply.
4. Rate limit on accept — nice-to-have; document as follow-up if not implemented.
