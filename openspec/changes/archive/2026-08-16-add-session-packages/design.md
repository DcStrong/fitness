## Context

Слои A/B/C закрыты: availability, RecurringBooking, coach book-at-time, календарный UX. Финансы — pay-per-session (`SessionCharge` при booking, earn на `completed` / chargeable `no_show`, ручная оплата). Лимита занятий нет: серия бессрочна до отмены.

Product #1 (`docs/roadmap/plan.md`): абонемент как **счётчик занятий** для пары trainer↔student. Деньги по-прежнему вне платформы (`docs/domain/billing.md`). Референс: `docs/design/availability-recurring-booking.md` § add-session-packages.

Constraints: NestJS + TypeORM (`backend/api/src`), Flutter Bloc/Cubit (`app/fitness_app`), API `localhost:3001`, Russian UI. Не смешивать с design polish волны B.

## Goals / Non-Goals

**Goals:**

- Тренер выдаёт ученику пакет из N занятий (± опциональный срок).
- UI показывает «осталось N»; списание по проведённым тренировкам.
- При исчерпании — in-app сигнал тренеру и подсказка продлить.
- Единые правила для recurring-материализованных и разовых Session.
- Продление / архив пакета.

**Non-Goals:**

- Эквайринг, автосписание, предоплата через API.
- Каталог типов пакетов, безлимит, семейные тарифы.
- Push/realtime; web console; polish B/C.
- Жёсткая остановка RecurringBooking sync при N=0 (только предупреждение).

## Decisions

### 1. Сущность `SessionPackage` — один active на пару coach–student

| Поле | Смысл |
|---|---|
| `id` | UUID |
| `coachId` / `studentId` | FK users; MUST active relationship |
| `totalSessions` | N при выдаче / после продлений (накопленный номинал текущего пакета) |
| `remainingSessions` | остаток; 0 → exhausted |
| `expiresAt` | nullable timestamptz; null = без срока |
| `status` | `active` \| `exhausted` \| `expired` \| `archived` |
| `createdAt` / `updatedAt` / `archivedAt` | |

Инвариант: **не более одного `active` пакета** на `(coachId, studentId)`. Partial unique index.

- **Create** — только если нет active; иначе 409 → продлить существующий.
- **Extend** — атомарно `remaining += addSessions`, `totalSessions += addSessions`, опционально сдвинуть/установить `expiresAt`; если был `exhausted`/`expired` и remaining станет > 0 и срок ок → снова `active`.
- **Archive** — тренер закрывает пакет (remaining замораживается); статус `archived`. Не удаляем строки (аудит).
- **Expired** — при чтении/списании если `expiresAt < now` и status был `active` → `expired` (ленивая маркировка; без отдельного cron в MVP).

Альтернатива — несколько параллельных active пакетов (очередь FIFO). Отклонена: усложняет UX «осталось N» и продление.

### 2. Списание: только terminal «проведено», не при `booked`

| Событие | Списание | Обоснование |
|---|---|---|
| Session создана / `booked` | **нет** | Иначе будущий горизонт recurring мгновенно съест пакет |
| `completed` | **да (−1)** | Совпадает с доменным заделом и «проведённой» тренировкой |
| `cancelled` | **нет** | Занятие не состоялось |
| `no_show` + `charge=true` | **да (−1)** | Симметрия с finance: платное неявка = расход пакета |
| `no_show` + `charge=false` | **нет** | Тренер явно не списывает |

Источник правды списания — хук в `SessionLifecycleService` (та же транзакция, что charge lifecycle), после успешного перехода статуса.

Идемпотентность: таблица `session_package_debits` (`packageId`, `sessionId` UNIQUE, `delta=-1`, `reason`, `createdAt`). Повтор complete не списывает дважды.

Если active пакета нет — lifecycle без изменений (pay-per-session only).

Если `remainingSessions == 0` уже `exhausted` — complete всё равно допускается; debit no-op (или skip); UI уже предупредил.

Альтернатива — reserve при book / release при cancel. Отклонена: ломает бессрочный recurring horizon и усложняет overrides.

### 3. Связь с RecurringBooking и разовыми Session

Пакет **не** FK на RecurringBooking. Любая Session пары `(coachId, studentId)` при qualifying terminal status списывает active пакет этой пары:

- материализация recurring;
- book-for-student / book-at-time;
- accepted BookingRequest.

`session.recurringBookingId` не влияет на правило списания.

При `remaining == 0` / `exhausted` / `expired`: **не блокируем** create Session и recurring sync. API list/detail пакета + опциональный флаг `packageWarning` на coach booking responses (или отдельный GET) для UI. Жёсткий stop sync — post-MVP.

### 4. SessionCharge и finance остаются независимыми

Абонемент — **счётчик занятий**, не замена ledger.

- При booking по-прежнему создаётся `SessionCharge` (снимок цены).
- `completed` / chargeable `no_show` по-прежнему earn charge; оплата — вручную.
- Package debit **не** меняет status charge и **не** создаёт income.

Тренер, продавший пакет вне приложения, может зафиксировать доход через существующий expense/income UX или помечать charges paid — вне автоматики этого change.

Альтернатива — auto-cancel charge при package debit. Отклонена в MVP: смешивает prepaid-семантику с pay-per-session без явной модели «пакет оплачен»; ломает accrued stats без отдельного package-sale income.

### 5. API surface и permissions

Новый module `session-packages` (рядом с billing/sessions):

| Method | Path | Кто |
|---|---|---|
| `POST` | `/session-packages` | coach: create `{ studentId, totalSessions, expiresAt? }` |
| `GET` | `/session-packages` | coach: list own; student: list own (как participant) |
| `GET` | `/session-packages/:id` | participant |
| `POST` | `/session-packages/:id/extend` | coach: `{ addSessions, expiresAt? }` |
| `POST` | `/session-packages/:id/archive` | coach |

Permissions: переиспользовать `relationships:read_own` + coach role для mutate; либо тонкие `packages:manage` / `packages:read_own` (seed в access-control при apply). Create требует active coach–student link.

Ответ включает `remainingSessions`, `status`, `expiresAt`, `student`/`coach` summary. После debit, если переход в `exhausted`, response lifecycle/session MAY включать `packageExhausted: true` для UI-сигнала (без push).

### 6. Flutter — минимальный UX (не polish B)

Точки входа (одна композиция на экран, без лишних карточных промо):

1. **Тренер — список учеников / связей** (`/relationships/me` или экран, где уже есть студенты): рядом с учеником «осталось N» / «нет пакета» / «исчерпан».
2. **Тренер — управление пакетом**: создать / продлить / архив с того же student context (sheet или простой экран). Recurring detail — read-only badge остатка (если студент известен), без отдельного «пакет = серия».
3. **Ученик — Home**: одна строка «Абонемент: осталось N» при active пакете; при exhausted — «пакет закончился, напишите тренеру».
4. После complete/no_show с exhaust — snackbar/banner тренеру «Пакет исчерпан — продлить».

Bloc/Cubit + repository; Russian copy; существующие design tokens без волны B.

### 7. Обнуление

Отдельного «reset to zero» нет: **archive** текущего + optional **create** нового, либо **extend** с нуля после exhausted. Явное «обнулить remaining» без archive не делаем (риск потери аудита).

## Risks / Trade-offs

- [Booked sessions «висят» сверх остатка] → Mitigation: UI warning; post-MVP optional soft-cap на sync.
- [Двойной учёт: package + unpaid charges] → Mitigation: docs + finance delta; не авто-cancel charge в MVP.
- [Ленивый expire] → Mitigation: expire check на read + перед debit; приемлемо для MVP.
- [Гонка двух complete] → Mitigation: row lock package + unique debit per sessionId.

## Migration Plan

1. Migration: `session_packages`, `session_package_debits` + partial unique active pair.
2. Deploy API (create/list/extend/archive + lifecycle hooks).
3. Flutter feature + badge на relationships/home.
4. Rollback: feature-flag не обязателен; archive endpoints остаются read-safe; хук debit no-op без строк пакета.

## Open Questions

- Нужны ли отдельные permission codes `packages:*` или достаточно coach role + relationship — решить при apply по паттерну billing permissions.
- Точный placement badge на trainer relationships vs recurring list — выбрать один primary list при реализации, второй — optional.
