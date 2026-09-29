# Промпт: рефакторинг типов в `backend/api`

Скопируй в Agent mode (при необходимости сузь список модулей).

---

Следуй skill **domain-interfaces** (`.cursor/skills/domain-interfaces/SKILL.md` + `reference.md`).

## Цель

В каждом доменном модуле под `backend/api/src/<domain>/` завести `interface/` и перенести туда все доменные `type`/`interface`. Убрать объявления типов из entity/service/controller и корневых `types.ts`. Публичные методы сервисов — с явными `*Params` / `*Returns` (или эквивалентными именами домена).

## Объём (по модулям)

Сделай по очереди, коммить/останавливайся после каждого модуля если попрошу; иначе — все:

1. `schedules` — `ScheduleSlotStatus`, `ScheduleSlotMode` из `database/entity/schedule-slot.entity.ts`; инлайны в `schedules.service.ts` (`createSlot` input, `list*` query, `toPublic`).
2. `sessions` — типы из `session.entity.ts` + инлайны в `sessions.service.ts`.
3. `invitations` — статусы из `invitation.entity.ts` + service params/returns.
4. `auth` — разнести `auth/types.ts` → `auth/interface/`; удалить корневой `types.ts`.
5. `access-control` — `PermissionCode`, `PublicRegisterRole` → `interface/` (const остаются в `constants.ts`).
6. `users`, `calendar` — вынести инлайн-типы сервисов при наличии.
7. Repository `*Params` для узких методов — в `interface/` владеющего домена, не в `.repository.ts`.

## Правила выполнения

- Entity только **импортирует** типы (`import type`), не экспортирует.
- `interface/` не импортирует Entity / TypeORM.
- Не менять поведение API, миграции, схему БД — только типы и сигнатуры.
- Обновить импорты по проекту; `as const` string literals в коде (`'open'`, `'offline'`) оставить совместимыми с union.
- Не дублировать одинаковые union без владельца (mode online/offline).
- После каждого модуля: проект должен компилироваться (`tsc` / `npm run build` в `backend/api`).

## Definition of Done

- [ ] Нет `export type` / `export interface` в `src/database/entity/*.ts`
- [ ] Нет корневых `src/**/types.ts` с доменными типами (есть `interface/`)
- [ ] У публичных методов сервисов нет анонимных object-типов во входе/выходе
- [ ] Каждый затронутый домен имеет `src/<domain>/interface/`
- [ ] Build зелёный

## Анти-scope

Не рефакторить DTO/OpenAPI контракты без нужды; не переносить entity в feature-папки; не менять runtime-логику.
