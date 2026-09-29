## Context

Phases 3–6 delivered the trainer MVP on Nest + Flutter. Phase 7 adds a **Next.js coach console** as a second client to the same API — desktop UX, not new domain features.

Repo layout today: `app/` (Flutter), `backend/` (Nest). This change introduces **`web_app/`** at the repo root (user preference; supersedes docs sketch of `apps/web` for this phase).

API already has permissive CORS. Auth is JWT access + refresh.

## Goals / Non-Goals

**Goals:**
- Scaffold `web_app/` with Next.js App Router + TypeScript.
- Trainer-only session: login, persist tokens, redirect guests, reject pure students.
- Console screens calling existing endpoints: relationships, slots, sessions (+ lifecycle/history), tags, plans.
- Local run: `web_app` → API on `:3001` (or env).

**Non-Goals:**
- Student web, marketing site, billing/social.
- Full mobile UI parity / heavy design-system port.
- Nest business endpoints; monorepo `packages/shared`.
- Server-side session cookies as primary auth (MVP: client-held tokens like mobile is OK).

## Decisions

### 1. Directory: `web_app/`
- Path: `/web_app` next to `app` and `backend`.
- Rejected: `apps/web` rename (docs target can update later); rejected Flutter Web.

### 2. Stack
- **Next.js** App Router, TypeScript, React.
- Data: **TanStack Query** (per stack.md) + thin `api` client (`fetch` wrapper with Bearer).
- UI: simple CSS modules / Tailwind optional — prefer minimal unstyled-or-light UI; brand green `#166246` from `app/design` as accent if cheap.
- Rejected: Vue/Nuxt for this change.

### 3. Auth model
- Login via `POST /auth/login`; store `accessToken` (+ refresh) in `localStorage` or memory+refresh pattern.
- On boot: `GET /users/me`; require role `trainer` (or any trainer-only permission e.g. `schedules:create`).
- Students see a clear «только для тренеров» / logout.
- Refresh: reuse `POST /auth/refresh` on 401 when possible (same as mobile intent).

### 4. Routes (MVP)
| Route | Purpose |
|-------|---------|
| `/login` | Auth |
| `/` or `/dashboard` | Home / nav hub |
| `/students` | Relationships list |
| `/slots` | Own schedule slots CRUD-ish |
| `/sessions` | List + complete/cancel/no-show + link to history |
| `/tags` | Tags + assign |
| `/plans` | Own plans CRUD |

RU copy. No QR create required in v1 if invite is awkward on web — **include invite create if API is simple** (`POST /invitations`); otherwise defer. Prefer include: create invite + show token/url (no QR library required).

### 5. API surface (existing only)
Reuse: auth, `/relationships/me`, `/schedule/slots`, `/sessions` (+ lifecycle), `/tags`, `/plans`. No new Nest modules.

### 6. Env
- `NEXT_PUBLIC_API_BASE_URL=http://localhost:3001`
- Document in `web_app/README.md` + root README pointer.

## Risks / Trade-offs

- [Token in localStorage XSS] → Mitigation: MVP acceptable; httpOnly cookies later.
- [Student opens web] → Mitigation: role gate after `/users/me`.
- [Incomplete parity] → Mitigation: document subset; mobile remains full coach client.
- [Docs say apps/web] → Mitigation: update repository.md note to `web_app` for current layout.

## Migration Plan

1. `create-next-app` (or equivalent) in `web_app/`.
2. Auth + shell + feature pages.
3. Smoke against local API with trainer account.
4. Archive OpenSpec; next phase billing/stats.

## Open Questions

None blocking — invite-on-web included if trivial; otherwise skip without blocking archive criteria.
