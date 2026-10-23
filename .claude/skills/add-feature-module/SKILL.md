---
name: add-feature-module
description: Add new feature module end-to-end. Use when creating a domain module with service, repository, and module wiring.
---
<!-- pipil-sync: из .cursor/skills/add-feature-module/SKILL.md. Правьте источник — копию обновит «Синхронизировать правила». -->

# Add Feature Module

## Чеклист

1. `src/module/<name>/` (в Fitness API: `src/<name>/`) — service, repository, **`interface/`**, index.ts.
2. Все доменные type/interface сразу в `interface/` — skill `domain-interfaces`.
3. Module — `examples/module/feature.module.ts`.
4. Register in AppModule.
5. Межмодульно — ports (`dynamic-register-async.ts`), не чужие repositories.

## Rule

`nestjs-modules.mdc`, `module-boundaries.mdc`, `domain-interfaces.mdc`

## Reference

[reference.md](reference.md)
