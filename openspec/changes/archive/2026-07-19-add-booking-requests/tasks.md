## 1. Persistence and Domain Foundations

- [x] 1.1 Add `@nestjs/schedule`, register `ScheduleModule`, and define booking-request status, reason, resolution, event, params, model, and returns types under `src/booking-requests/interface/`
- [x] 1.2 Add TypeORM `BookingRequestEntity` and append-only `BookingRequestEventEntity` with request/slot/user/Session relations and quoted-price/expiry/decision fields
- [x] 1.3 Add a migration for booking request tables, CHECK/FK/index constraints, one-pending-per-slot and one-pending-per-coach-student partial unique indexes
- [x] 1.4 Add pure persistence repositories for booking requests/events with owner-scoped paginated queries, pending count, row-lock helpers, and idempotent due-expiry update
- [x] 1.5 Wire entities/repositories into a new `BookingRequestsModule` without introducing domain decisions into repositories

## 2. Request Lifecycle and API

- [x] 2.1 Implement lifecycle rules/constants for 12-hour/2-hour deadline calculation and allowed pending terminal transitions with deterministic unit tests
- [x] 2.2 Implement transactional student request creation with relationship/slot/price revalidation, quote snapshot, partial-unique conflict mapping, and creation event
- [x] 2.3 Implement student own-list and withdraw use cases with status filtering, bounded pagination, ownership checks, expiry refresh, and event persistence
- [x] 2.4 Implement trainer inbox/pending-count use cases with trainer ownership, urgent pending ordering, pagination, and safe counterpart summaries
- [x] 2.5 Implement transactional accept and reject use cases, including required rejection reason, optional bounded student-visible comment, exactly-once event, and rollback on charge failure
- [x] 2.6 Implement alternate-time resolution with linked contacts, coach serialization, duration/mode copied from the requested slot, conflict validation, one-off slot, Session/charge, and accepted event
- [x] 2.7 Implement idempotent scheduled plus lazy expiry processing that releases logical holds and records one expiry event
- [x] 2.8 Add validated DTOs, response mapping, controller endpoints, and permission/resource guards for create/mine/withdraw/inbox/count/accept/reject/alternate

## 3. Calendar, Session, and Finance Integration

- [x] 3.1 Update student availability queries to exclude non-expired held slots while trainer own-slot responses expose held state safely
- [x] 3.2 Prevent deletion of held slots and serialize slot creation/direct booking/request decisions using the agreed coach lock strategy
- [x] 3.3 Refactor the calendar booking primitive to accept an explicit immutable request quote while preserving coach direct default/override booking
- [x] 3.4 Reject direct student `POST /sessions` even for stale `sessions:book_self` tokens and return an actionable request-flow error
- [x] 3.5 Ensure accepted requested/alternate flows atomically persist request status/event, resolved slot, Session, and exactly one quoted-price charge

## 4. Contact Privacy

- [x] 4.1 Add phone, Telegram username, and preferred-contact-channel domain types plus validated nullable columns on `UserProfileEntity` in a migration
- [x] 4.2 Extend own-profile DTO/service/response mapping to normalize contacts, validate selected channels, and use account email as fallback
- [x] 4.3 Add linked-contact endpoint and projection guarded by `profiles:read_linked_contacts` plus active relationship policy
- [x] 4.4 Verify public discovery/profile/review DTO mappers never expose phone, Telegram, preferences, email, or BookingRequest data

## 5. Permissions and Backend Verification

- [x] 5.1 Add booking-request and linked-contact permission constants/seeds; replace student `sessions:book_self` assignment with request create/read-own while preserving trainer permissions
- [x] 5.2 Add service/controller unit tests for authorization, ownership, rejection validation, deadline calculation, expiry idempotency, and response mapping
- [x] 5.3 Add database/e2e coverage for concurrent create/accept, one-pending constraints, held availability/deletion, withdraw/reject/expiry, quote stability, and transactional rollback
- [x] 5.4 Add privacy/e2e coverage for own contact updates, linked-only contact reads, unlinked denial, and absence of PII from every public projection
- [x] 5.5 Add alternate-time e2e coverage for conflict rejection, copied duration/mode, original slot remaining open, one-off Session/charge, and missing relationship
- [x] 5.6 Update backend live references/OpenAPI artifacts as required, run formatting, targeted tests, full test suite, lint, and build

## 6. Flutter Data and State Layers

- [x] 6.1 Add typed BookingRequest, request event/summary, linked contact, pagination, rejection, and resolution models without raw status strings in presentation logic
- [x] 6.2 Add `BookingRequestsRepository` Dio methods for all request endpoints with Russian conflict/error mapping and repository unit tests
- [x] 6.3 Extend profile repository/models for contact fields and preferred channels while keeping public trainer models free of private fields
- [x] 6.4 Add student requests Cubit/Bloc with load/refresh/create/withdraw and initial/loading/empty/success/failure/submitting/conflict states plus bloc tests
- [x] 6.5 Add trainer inbox Cubit/Bloc with pagination/refresh/count and accept/reject/alternate mutation states plus bloc tests

## 7. Flutter Student Request Experience

- [x] 7.1 Replace direct student Session booking with a review sheet and «Отправить заявку» action showing requested time, mode, quote, and pending explanation
- [x] 7.2 Add «Мои заявки» Page/View with localized pending/accepted/rejected/withdrawn/expired cards, feedback, resolved time, Session navigation, and pull-to-refresh
- [x] 7.3 Add pending-only withdrawal confirmation and refresh requestable slots after create/withdraw/conflict
- [x] 7.4 Add widget tests for request submission, duplicate/held/deadline conflict copy, all terminal states, rejection feedback, and withdrawal

## 8. Flutter Trainer Inbox and Alternate Flow

- [x] 8.1 Add trainer «Заявки» Page/View with urgent pending-first cards, pagination, loading/empty/error/retry, and duplicate-action disabling
- [x] 8.2 Add request detail/decision UI for accept and reject with required reason choices and optional bounded comment
- [x] 8.3 Add alternate-time bottom sheet showing linked preferred contacts/email fallback, external-agreement guidance, local date/time selection, and final confirmation
- [x] 8.4 Add widget tests for accept/reject/alternate success, validation/conflict/failure, contact fallback, and no counter-proposal UI

## 9. Flutter Profile, Home, and Routing

- [x] 9.1 Add own-profile contact inputs and preferred-channel controls with Russian validation and linked-only privacy explanation
- [x] 9.2 Extend Home state to load pending count independently from daily Sessions and render an actionable trainer-only badge without converting count failure to zero
- [x] 9.3 Register authenticated role-aware own-request, trainer-inbox, and request-detail routes with discoverable role-appropriate navigation while preserving existing deep links and backend authorization
- [x] 9.4 Add route/Home/profile widget tests for role visibility, navigation discoverability, badge refresh after decisions, count failure isolation, contact validation, and logged-out redirects

## 10. End-to-End Validation

- [x] 10.1 Run backend migration/seed against a clean local database and verify refreshed trainer/student permissions
- [x] 10.2 Run backend lint/build/unit/e2e and Flutter format/analyze/full tests; fix regressions introduced by this change
- [x] 10.3 Launch local API and Flutter app, smoke student create/track/withdraw and trainer accept/reject/alternate flows with two linked accounts
- [x] 10.4 Verify UI on compact and standard mobile viewports, request navigation/discoverability, expiry/held-slot refresh, Home badge, profile privacy, and existing coach direct booking
- [x] 10.5 Record intentional deviations, validate `add-booking-requests`, mark all completed tasks, and stop before recurring availability or full calendar work

## Implementation Notes

- The agreed API does not include `GET /booking-requests/:id`. Flutter detail navigation therefore passes a typed request from a loaded list; a cold direct deep link without that payload shows a role-aware fallback to the corresponding list.
- The local API and Flutter driver application were launched without application runtime errors. Two linked smoke accounts exercised live withdraw, reject, requested-slot accept, alternate-slot accept, pending count, and owner-scoped list responses; deterministic edge cases remain covered by backend e2e and Flutter repository/Cubit/widget tests.
- Student and trainer request destinations are now persistent role-aware navigation items. Trainer Home still provides the additional positive-count badge, but inbox/history remains discoverable when the count is zero or unavailable.
- Request screens and both role navigation variants pass compact `320x700` and standard `390x844` viewport tests.
- Feature-focused backend lint has zero errors. Project-wide lint still reports 184 errors and 534 warnings in pre-existing legacy areas outside this change; no project-wide auto-fix or unrelated cleanup was applied.

## Validation Findings — Resolved

- Student navigation now exposes «Мои заявки» directly; it no longer depends on access to Home.
- Trainer navigation now exposes «Заявки» independently of the Home pending-count result.
- Route/destination tests cover role visibility, list/detail selection, logged-out redirects, and shared schedule-branch highlighting.
