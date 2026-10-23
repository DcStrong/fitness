---
name: rule-module-boundaries
description: Module boundaries and portability
---
<!-- pipil-sync: из .cursor/rules/module-boundaries.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# Module Boundaries

- Feature slice: service, interface, helper, mapper внутри модуля.
- `#common` — только truly-shared примитивы.
- Межмодульно: ports/adapters или events, не прямой import чужого repository.
- CQRS handler — в домене, infra только publish (`cqrs-handler-in-domain.ts`).

Доменные ошибки без HTTP; HTTP на границе controller/filter.
