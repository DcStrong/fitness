## 1. Bootstrap web_app

- [x] 1.1 Scaffold Next.js (App Router, TypeScript) in repo-root `web_app/`
- [x] 1.2 Add env example (`NEXT_PUBLIC_API_BASE_URL`) + `web_app/README.md` run steps; link from root README / update `docs/architecture/repository.md` path note
- [x] 1.3 Add thin API client (Bearer token, base URL, JSON errors)

## 2. Auth & shell

- [x] 2.1 Login page (RU) → `/auth/login`; persist access (+ refresh); call `/users/me`
- [x] 2.2 Trainer gate: reject student-only users; protect console routes; logout (+ revoke refresh when available)
- [x] 2.3 App shell with nav: Ученики, Слоты, Занятия, Теги, Планы

## 3. Coach console features

- [x] 3.1 Students: list `/relationships/me`
- [x] 3.2 Slots: list/create/delete open own slots
- [x] 3.3 Sessions: list; complete / cancel / no-show; history view
- [x] 3.4 Tags: create/list/delete; assign to linked student
- [x] 3.5 Plans: list/create/edit own plans with tagIds

## 4. Verification & docs

- [x] 4.1 Manual smoke: trainer login → each section against local API; student denied
- [x] 4.2 Optional: invite create page if trivial (`POST /invitations` + show URL)
