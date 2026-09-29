---
name: refactor-module
description: Safe module refactor without breaking DI. Use when moving handlers, fixing cross-module deps.
---

# Refactor Module

Эталон anti-pattern → fix: `examples/module/cqrs-handler-in-domain.ts`

1. `yarn test:unit` baseline.
2. Перенос handlers в доменный module.
3. Ports вместо прямых imports.
4. Re-run tests.

Rule: `module-boundaries.mdc`, `nestjs-modules.mdc`

For full service migration use `refactor-service-to-platform`.
