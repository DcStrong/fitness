---
name: rule-nestjs-modules
description: Module wiring, dynamic modules, CQRS placement
---
<!-- pipil-sync: из .cursor/rules/nestjs-modules.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# NestJS Modules

Эталоны: `platform/examples/module/`

- Feature: `feature.module.ts` — forFeature, providers, exports.
- Dynamic + ports: `dynamic-register-async.ts`.
- CQRS handler в **доменном** модуле: `cqrs-handler-in-domain.ts`.

## ✅ / ❌

```typescript
// ✅ ItemModule imports QueueModule, provides SaveItemCommandHandler
// ❌ QueueModule imports ItemRepository
```

Переносимость: `module-boundaries.mdc`.
