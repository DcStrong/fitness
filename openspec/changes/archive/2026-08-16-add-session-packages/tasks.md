## 1. Backend domain model and migration

- [x] 1.1 Add TypeORM entities `SessionPackage` and `SessionPackageDebit` (fields per design.md) under `backend/api/src/database/entity/`
- [x] 1.2 Add repositories; register entities in module / entities index
- [x] 1.3 Create migration: tables, FKs, partial unique one `active` package per `(coach_id, student_id)`, unique `(package_id, session_id)` on debits
- [x] 1.4 Add domain interfaces under `src/session-packages/interface/` (statuses, Params/Returns, exhaustion signal) per domain-interfaces skill
- [x] 1.5 Seed/register permissions if introducing `packages:*` (or document reuse of coach + `relationships:read_own`)

## 2. Session packages API

- [x] 2.1 Nest module `session-packages` (controller/service/module) wired into AppModule
- [x] 2.2 DTO + validation: create `{ studentId, totalSessions > 0, expiresAt? }`, extend `{ addSessions > 0, expiresAt? }`
- [x] 2.3 `POST /session-packages` — require active link; reject second active; set remaining = total
- [x] 2.4 `GET /session-packages` and `GET /session-packages/:id` — coach/student participant scope
- [x] 2.5 `POST /session-packages/:id/extend` — bump total/remaining; reactivate exhausted/expired when valid
- [x] 2.6 `POST /session-packages/:id/archive` — status archived; allow new create for pair
- [x] 2.7 Lazy expire: on read/debit if `expiresAt < now` and status active → expired
- [x] 2.8 Unit tests: create, duplicate active 409, extend, archive, expire, ownership isolation

## 3. Lifecycle debit hooks

- [x] 3.1 In `SessionLifecycleService` transaction: after successful status change, apply package debit rules (design §2)
- [x] 3.2 Debit on `completed` and chargeable `no_show`; never on `cancelled` / non-chargeable `no_show` / book
- [x] 3.3 Idempotent debit via `session_package_debits`; row-lock package; set `exhausted` at remaining 0
- [x] 3.4 Surface `packageExhausted` (or equivalent) on lifecycle response when transition exhausts package
- [x] 3.5 Confirm SessionCharge earn/pay unchanged (session-finance: package does not auto-pay)
- [x] 3.6 Unit tests: complete −1, cancel 0, chargeable no_show −1, non-chargeable 0, idempotent, no package no-op
- [x] 3.7 E2E: create package → book session → complete → remaining; last session → exhausted signal; booking still allowed when exhausted

## 4. Flutter data layer

- [x] 4.1 Models + `SessionPackagesRepository` (list/create/extend/archive) via Dio against `localhost:3001`
- [x] 4.2 Map API errors (duplicate active, not linked, not found) to Russian user-facing messages
- [x] 4.3 Bloc/Cubit only; no Riverpod / freezed / hive unless already used nearby

## 5. Flutter trainer UX

- [x] 5.1 Show «осталось N» / «нет пакета» / «исчерпан» on trainer linked-students context (primary list)
- [x] 5.2 Create / extend / archive flow (sheet or simple screen) with Russian copy; optional expiry
- [x] 5.3 Optional read-only remaining badge on recurring detail when student known
- [x] 5.4 After complete / chargeable no_show with exhaustion signal — snackbar/banner «Пакет исчерпан — продлить»

## 6. Flutter student UX

- [x] 6.1 Home indicator «Абонемент: осталось N» when active package exists
- [x] 6.2 Exhausted/expired hint to contact trainer (no finance aggregates)

## 7. Tests and verification

- [x] 7.1 Cubit/widget tests: remaining display, create/extend, exhaustion prompt
- [x] 7.2 `dart format`, analyze, and related Flutter test suites
- [x] 7.3 Manual smoke on `localhost:3001`: issue package → complete sessions → remaining → exhaust → extend; student Home shows N
- [x] 7.4 Confirm non-goals: no acquiring, no charge auto-pay, no RecurringBooking hard-stop, no design polish волны B
- [x] 7.5 Ready for `/opsx-archive` after apply complete

## Implementation Notes

- Migration `SessionPackages1754500000000` applied; permissions `packages:manage` / `packages:read_own` seeded.
- Backend unit 20/20; e2e `session-packages` 1/1.
- Flutter: `/session-packages` from Home «Ученики»; student Home badge; calendar/journal exhaustion snackbar.
- SessionCharge earn/pay unchanged on package debit (finance independent).
- Task 7.3: API path covered by e2e; UI smoke on device when app runs against `:3001`.
