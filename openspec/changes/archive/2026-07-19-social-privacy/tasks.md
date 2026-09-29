## 1. Persistence and permissions

- [x] 1.1 Add social/profile domain interfaces under `src/social/interface/` for owner/public profiles, privacy, discovery pages, portfolio, reviews, eligibility, and rating
- [x] 1.2 Add `UserProfile`, `TrainerPortfolioItem`, and `SessionReview` entities; register repositories and module wiring
- [x] 1.3 Add TypeORM migration with hidden privacy defaults, rating/length checks, unique Session review, ownership FKs, and discovery/review indexes
- [x] 1.4 Extend permission constants and seed with profile/privacy/portfolio/review permissions for trainer and student
- [x] 1.5 Run migration and seed locally; verify legacy users remain valid and absent from discovery

## 2. Own profile and privacy

- [x] 2.1 Implement `GET/PUT /profiles/me` with normalized fields, limits, HTTPS URL validation, and lazy profile creation
- [x] 2.2 Implement `PUT /profiles/me/privacy` with trainer publication requirements and student discoverability prohibition
- [x] 2.3 Add separate owner/public profile mappers and contract assertions that public responses exclude PII, operational, and finance fields
- [x] 2.4 Add permission and ownership tests for own profile/privacy reads and writes

## 3. Trainer discovery and portfolio

- [x] 3.1 Implement filtered/paginated `GET /trainers` with discoverable-trainer scope, bounded limit, derived rating, and stable order
- [x] 3.2 Implement `GET /trainers/:id` with hidden-profile 404 behavior and viewer-scoped `isLinked` only
- [x] 3.3 Implement owner portfolio create/update/reorder/delete endpoints with item count, text, order, and HTTPS URL limits
- [x] 3.4 Include ordered portfolio only in owner preview and currently discoverable public profile responses
- [x] 3.5 Unit/integration-test discovery filters, pagination, hidden UUID enumeration, foreign portfolio access, and public DTO privacy

## 4. Verified reviews and ratings

- [x] 4.1 Implement `POST /sessions/:id/review` with completed-Session/student ownership policy and race-safe one-review constraint
- [x] 4.2 Implement own-review `PUT /reviews/:id`; reject trainer/foreign edits and invalid rating/text
- [x] 4.3 Implement `GET /reviews/eligible` and `GET /reviews/mine` scoped to the authenticated student
- [x] 4.4 Implement trainer owner review list and paginated public trainer reviews with reviewer privacy projection
- [x] 4.5 Implement derived average/count queries and enforce `showRating`/`showReviews` at read time
- [x] 4.6 Add API smoke: hidden profile → publish → discover → completed Session review → edit → aggregate/privacy; verify outsider and duplicate denial
- [x] 4.7 Update Postman collection for profile, discovery, portfolio, privacy, and review flows

## 5. Flutter mobile

- [x] 5.1 Add social models/repository for owner profile, privacy, discovery pagination, public profile, portfolio, reviews, and eligibility
- [x] 5.2 Add discovery Bloc/Page/View with query/specialty/mode filters, pagination, empty/error/retry states, and Russian UI
- [x] 5.3 Add trainer public profile with safe image fallbacks, portfolio/reviews/rating visibility, and linked/invitation-required CTA
- [x] 5.4 Add own profile/privacy editor for both roles with trainer publication and student reviewer-attribution controls
- [x] 5.5 Add eligible Session review creation/edit flow and refresh Session/social state after save
- [x] 5.6 Register authenticated social routes and student «Тренеры / Тренировки / Профиль» navigation while preserving trainer home
- [x] 5.7 Add formatter/Bloc/widget tests; run Dart format/analyze/tests and trainer+student runtime smoke

## 6. Web coach console

- [x] 6.1 Add profile/privacy/portfolio/review API types and client methods with public/owner DTO separation
- [x] 6.2 Add «Публичный профиль» navigation and coach-only `/profile` owner form
- [x] 6.3 Add privacy controls and owner preview that clearly distinguishes hidden and published state
- [x] 6.4 Add portfolio create/edit/reorder/delete UI with validation and safe image fallback
- [x] 6.5 Add read-only received reviews and derived rating/count without student PII or mutation actions
- [x] 6.6 Run production build and trainer/student browser smoke against the local API

## 7. Documentation

- [x] 7.1 Add `docs/domain/social-privacy.md` covering opt-in discovery, public DTO boundaries, invitation-first flow, portfolio, verified reviews, rating, and privacy semantics
- [x] 7.2 Update domain entities/processes, product roles/features, and roadmap terminology for the completed social/privacy vertical
