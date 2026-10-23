<!-- pipil-sync:rules start -->
## Правила проекта (из .cursor/rules)

<!-- pipil-sync: из .cursor/rules. Правьте источник — копию обновит «Синхронизировать правила». -->

### platform-overview

# NestJS Platform

Портативный слой в `.cursor/platform/`. Примеры: `platform/examples/` (не зависят от `src/`).

**Активация:** `./.cursor/activate.sh` (platform + project → `.cursor/rules`, `.cursor/skills`).

**Стек (типовой):** NestJS, TypeORM, OpenAPI → generated contracts, passport-jwt, CQRS, Sentry.

**Workflow skills:** `add-api-endpoint`, `add-feature-module`, `refactor-service-to-platform`, `write-unit-test`, `write-e2e-test`.

**Rules:** `import-aliases.mdc`, `typescript-typing.mdc`.

**Project overlay:** `.cursor/project/` — домен, команды, live-references.

### project-map

# Fitness Yoda — карта для агента

## Monorepo

| Путь | Стек |
|------|------|
| `app/fitness_app/` | Flutter: Bloc/Cubit, go_router, dio |
| `backend/api/` | NestJS + TypeORM; модули плоско в `src/<domain>/` |
| `web_app/` | Next.js консоль **только тренера** |
| `docs/` | продукт / домен / архитектура |
| `openspec/` | specs + changes |

Живой индекс (домен ↔ код ↔ спека ↔ архив): `.cursor/project/docs/map.md`.

## Словарь

- **coach** = **trainer** (в API-ролях: `trainer` \| `student`)
- **student** = ученик / клиент
- Код и идентификаторы — English; UI-строки — русский

## Порты (dev)

- API: `http://localhost:3001`
- Web: `http://localhost:3000`

## Источник правды

1. Явные решения в чате / активный OpenSpec change  
2. `openspec/specs/<capability>/spec.md`  
3. `docs/`  

## OpenSpec

- Активные: `openspec/changes/<name>/` (`proposal.md`, `design.md`, `tasks.md`, delta-specs)
- Baseline: `openspec/specs/<capability>/spec.md`
- Архив: `openspec/changes/archive/YYYY-MM-DD-<name>/` — читать **точечно** по строке из `map.md`, не листить всю папку
- Команды: `/opsx-explore`, `/opsx-propose`, `/opsx-apply`, `/opsx-update`, `/opsx-sync`, `/opsx-archive`

## Протокол (экономия токенов)

1. Перед широким glob/grep — прочитать `.cursor/project/docs/map.md`
2. Открыть одну baseline-спеку (и при необходимости один архивный `proposal.md` / `design.md`)
3. Только потом — код в указанной папке
4. Скилл ориентации: `project-orientation`

Правила: править только `.cursor/project/` (и при необходимости `activate.sh`). **Не** трогать user/global rules и `.cursor/platform/`. Активные `.cursor/rules` / `.cursor/skills` — копии из `./.cursor/activate.sh` (скрипт также дописывает Nest-глобы `backend/api/src/**` в активные rules).

### utils-vs-helpers

# Util vs Helper

**Util** (`**/util/*.util.ts`) — универсальный примитив без домена/фреймворка: `parseBoolean`, `requireEnv`.

**Helper** (`**/helper/*.helper.ts`) — контекст (TypeORM QB, Sentry, class-transformer, domain).

Вопрос: *можно вызвать из любого модуля без контекста?* Да → util. Нет → helper.

Не смешивать суффиксы `.util.ts` / `.helper.ts`.
<!-- pipil-sync:rules end -->
