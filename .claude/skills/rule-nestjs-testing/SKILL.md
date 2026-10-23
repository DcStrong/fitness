---
name: rule-nestjs-testing
description: Unit and E2E test patterns
---
<!-- pipil-sync: из .cursor/rules/nestjs-testing.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# Тестирование

Эталоны: `platform/examples/testing/`

- `describe`/`it` — на русском, одна мысль на `it`.
- Unit: моки **границ** (repository, external clients), не policy/asserts.
- E2E: `createTestApp` + overrides, contract assertions, DB cleanup.

```typescript
// ❌ expect(x).toBeDefined() как единственная проверка
```

Skills: `write-unit-test`, `write-e2e-test`.
