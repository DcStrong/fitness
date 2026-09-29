## 1. Backend data & permissions

- [x] 1.1 Add TypeORM entities: `Invitation`, `CoachStudentLink` (+ indexes, unique coach–student)
- [x] 1.2 Create migration for new tables
- [x] 1.3 Extend permission constants + seed (`invitations:*`, `relationships:read_own`) for trainer/student roles
- [x] 1.4 Run migration + seed on local DB

## 2. Backend invitations API

- [x] 2.1 Nest module `invitations`: create / list own / revoke (permission-gated)
- [x] 2.2 Accept by token: validate pending+expiry+not-self; set accepted; upsert coach–student link
- [x] 2.3 `GET /relationships/me` (or equivalent) for own links
- [x] 2.4 Update Postman collection with new endpoints
- [x] 2.5 API smoke: trainer create → student accept → both see relationship

## 3. Mobile invitations feature

- [x] 3.1 Add deps as needed (`qr_flutter`, etc.); feature folder `lib/features/invitations`
- [x] 3.2 `InvitationsRepository` + models against new API
- [x] 3.3 Trainer invite screen: create invitation, show QR, copy HTTPS invite URL (RU copy)
- [x] 3.4 Student accept flow: deep link / query token, pending-token across auth, accept + errors (RU)
- [x] 3.5 Wire `go_router` routes `/invite`, `/invite/accept`; auth redirects
- [x] 3.6 Home stub: load relationships and show linked coach/students (RU)

## 4. Deep link stubs & verification

- [x] 4.1 Document/configure placeholder scheme `fitnessyoda://invite/<token>` + HTTPS `https://app.fitness-yoda.local/i/<token>`
- [x] 4.2 Manual smoke mobile: trainer QR/copy → student accept (auth if needed) → home shows link
- [x] 4.3 Optional: cubit unit test for accept success/failure with mocked repository
