# Refactor to platform — gap table template

| Паттерн | Статус | Live path in repo | Platform example |
|---------|--------|-------------------|------------------|
| Controller command flow | ✅/⚠️/❌ | `src/...` | `examples/controller/command-handler.ts` |
| List ResponseDto | | | `list-handler.ts` |
| Auth middleware+guard | | | `auth/middleware-guard-flow.md` |
| Repository preload-save | | | `repository/preload-save-reload.ts` |
| CQRS in domain module | | | `module/cqrs-handler-in-domain.ts` |
| E2E contract tests | | | `testing/e2e-app-setup.ts` |

## Промпт для агента

```
Прочитай .cursor/platform/ и skill refactor-service-to-platform.
Сделай discovery → gap table → рефактор по приоритету.
Живые пути только в project/docs/live-references.md.
```
