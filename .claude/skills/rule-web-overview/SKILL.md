---
name: rule-web-overview
description: Fitness Yoda web console (Next.js trainer-only)
---
<!-- pipil-sync: из .cursor/rules/web-overview.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# Web (Fitness Yoda)

- Next.js App Router console for **trainers only** (`web_app/`).
- Same Nest API as mobile: `http://localhost:3001` (`NEXT_PUBLIC_API_BASE_URL`).
- Students see “trainers only” after login — do not build student flows here.
- Specs: `web-app-bootstrap`, `web-coach-auth`, `web-coach-console`, `web-finance`, `web-social`.
- Product map: `.cursor/project/docs/map.md`.
