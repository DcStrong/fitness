## 1. Data & permissions

- [x] 1.1 Add `SessionHistoryEvent` entity + types in `sessions/interface/` (entity only `import type`)
- [x] 1.2 Migration for `session_history_events` (+ indexes)
- [x] 1.3 Extend permission constants + seed (`sessions:complete`, `sessions:cancel`, `sessions:mark_no_show`, `sessions:read_history`)
- [x] 1.4 Run migration + seed on local DB

## 2. Backend lifecycle & history API

- [x] 2.1 Domain Params/Returns for transitions + history list under `sessions/interface/`
- [x] 2.2 `SessionLifecycleService` (or sessions service methods): validate participant + status + transition; transactional status update + history insert
- [x] 2.3 Endpoints: `POST /sessions/:id/complete`, `/cancel`, `/no-show`; reject illegal transitions
- [x] 2.4 `GET /sessions/:id/history` for participants with `sessions:read_history`
- [x] 2.5 Optional `status` filter on `GET /sessions`
- [x] 2.6 Enforce cancel does **not** reopen schedule slot
- [x] 2.7 Update Postman collection
- [x] 2.8 API smoke: book → complete / cancel / no_show; illegal transition 4xx; history list; outsider forbidden

## 3. Mobile UI

- [x] 3.1 Sessions API client methods (complete/cancel/noShow/history + optional status filter)
- [x] 3.2 Sessions list: show status; actions for `booked` by role (RU)
- [x] 3.3 Session history screen + go_router `/sessions/:id/history`
- [x] 3.4 Wire navigation from sessions list; avoid ListTile+wide trailing button layout pitfalls

## 4. Docs & verification

- [x] 4.1 Update `docs/architecture/calendar.md` phase 5 notes (transitions + history; slot-reopen deferred)
- [x] 4.2 Manual smoke mobile (trainer + student) against local API
- [x] 4.3 Optional: unit test illegal transition / history append
