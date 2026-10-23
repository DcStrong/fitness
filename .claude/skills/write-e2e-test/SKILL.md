---
name: write-e2e-test
description: E2E test with auth, fixtures, contract assertions. Use when adding test/e2e/*.e2e-spec.ts.
---
<!-- pipil-sync: из .cursor/skills/write-e2e-test/SKILL.md. Правьте источник — копию обновит «Синхронизировать правила». -->

# Write E2E Test

Эталон: `platform/examples/testing/e2e-app-setup.ts`

1. `createTestApp()` + override external deps.
2. Auth header helper для protected routes.
3. `assertResponseMatchesContract` — не менять контракт без смены API.
4. DB cleanup в `afterEach`.

Rule: `nestjs-testing.mdc`

## Reference

[reference.md](reference.md)
