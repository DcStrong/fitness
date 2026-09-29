## Context

Session уже является каноническим фактом занятия и имеет terminal lifecycle (`completed`, `cancelled`, `no_show`). Каждое новое занятие платное, но Fitness Yoda не принимает деньги: тренер получает наличные или внешний перевод и вручную фиксирует расчёт.

Фаза должна различать:

- **начислено / earned** — занятие состоялось или оплачиваемая неявка;
- **получено / received** — тренер подтвердил фактическую оплату;
- **ожидается / outstanding** — начислено, но не оплачено;
- **расходы / expenses** — ручные операции тренера;
- **чистый доход / net cash** — получено минус расходы.

Финансовые правила принадлежат backend. Flutter и Next.js остаются тонкими клиентами. Все доменные типы — в `src/billing/interface/`.

## Goals / Non-Goals

**Goals:**

- Положительная базовая цена занятия и одна валюта тренера.
- Неизменяемый price snapshot на booking.
- Одно начисление на Session и атомарная связь с lifecycle.
- Ручное подтверждение оплаты без платёжного провайдера.
- Append-only журнал доходов, расходов и корректировок.
- Проверяемые агрегаты по ISO `from`/`to`.
- Полный trainer flow в Flutter и web; student read-only price/payment summary.

**Non-Goals:**

- Эквайринг, карты, webhook платёжной системы, касса и чеки.
- Подписки, абонементы, скидки, возвраты и частичная оплата.
- Налоговая отчётность и конвертация валют.
- Автоматическое решение о платности `no_show`.
- Физическое удаление/редактирование проведённых ledger entries.

## Decisions

### 1. Money хранится в minor units

- `amountMinor: bigint` / PostgreSQL `bigint`; API отдаёт decimal-safe integer как string либо безопасный integer в пределах JS (предпочтительно string в contract).
- `currency: char(3)`, MVP — `RUB`.
- Float/decimal в бизнес-расчётах запрещён.

Это исключает ошибки округления. В UI `150000` minor units отображается как `1 500,00 ₽`.

### 2. Настройки цены тренера

`CoachFinanceSettings`:

- `coachId` (PK/FK);
- `defaultSessionPriceMinor` (> 0);
- `currency` (MVP immutable после появления финансовых записей либо только `RUB`);
- `updatedAt`.

API:

- `GET /finance/settings`;
- `PUT /finance/settings { defaultSessionPriceMinor, currency }`.

Новый booking MUST быть отклонён понятной ошибкой, если у тренера нет положительной цены. Coach-booking MAY передать `priceMinor` override; student self-booking всегда использует текущую default price. Слот linked coach возвращает текущую цену, чтобы студент видел стоимость до подтверждения.

### 3. Цена и начисление — snapshot, не вычисление из текущего тарифа

`SessionCharge` (1:1 с Session):

- `id`, `sessionId` unique, `coachId`, `studentId`;
- `amountMinor`, `currency`;
- `status: pending | paid | cancelled`;
- `earnedAt` nullable;
- `paidAt` nullable;
- `paymentMethod: cash | transfer | card | other` nullable;
- `cancelledAt` nullable;
- timestamps.

Charge создаётся в той же booking transaction, что Session, из актуальной цены. Изменение settings не меняет существующие charges.

`pending` до завершения не означает долг: outstanding учитывает только charge с `earnedAt != null`.

### 4. Lifecycle → finance policy

Все изменения Session + Charge + ledger происходят атомарно:

| Session transition | Charge |
|---|---|
| booking → `booked` | create `pending`, `earnedAt = null` |
| `booked → completed` | `pending`, set `earnedAt = transition time` |
| `booked → cancelled` | `cancelled`, set `cancelledAt`; earned = 0 |
| `booked → no_show { charge: true }` | `pending`, set `earnedAt` |
| `booked → no_show { charge: false }` | `cancelled` |

`no-show` endpoint получает обязательное billing-решение `{ charge: boolean }`; оба клиента обновляются в этом change.

Mark-paid разрешён только для `pending` charge с `earnedAt != null`. Это исключает paid→cancelled/refund в MVP.

### 5. Оплата и ledger

`POST /finance/charges/:id/mark-paid { paymentMethod, paidAt? }`:

- в одной transaction переводит charge `pending → paid`;
- добавляет ровно одну `FinanceLedgerEntry(type=income, source=session_charge)`;
- повторный вызов идемпотентен либо возвращает conflict без duplicate entry.

`FinanceLedgerEntry`:

- `id`, `coachId`;
- `type: income | expense | adjustment`;
- `amountMinor` signed для adjustment, positive для income/expense;
- `currency`;
- `sourceType: session_charge | manual`;
- `sourceId` nullable;
- `category` nullable/простая строка;
- `note` nullable;
- `occurredAt`, `createdAt`;
- `reversesEntryId` nullable.

Entries append-only. Ошибка исправляется reversal/adjustment, не UPDATE/DELETE.

Manual expense:

- `POST /finance/expenses { amountMinor, category?, note?, occurredAt? }`.

Для MVP отдельный произвольный manual income не нужен: доход привязан к занятиям. Корректировка доступна тренеру только для исправления журнала.

### 6. Статистика — производная, не mutable balance

`GET /finance/summary?from=<ISO>&to=<ISO>` возвращает одну валюту:

- `accruedMinor`: charges с `earnedAt` внутри периода, кроме cancelled;
- `receivedMinor`: income ledger по `occurredAt` внутри периода;
- `outstandingMinor`: earned pending charges (срез на момент запроса; дополнительно список долгов);
- `expensesMinor`: expense entries внутри периода;
- `adjustmentsMinor`;
- `netMinor = received - expenses + adjustments`;
- counts: completed/no_show chargeable, paid, outstanding.

`GET /finance/ledger?from&to&type&studentId?` и `GET /finance/debts`.

Клиент формирует границы дня/недели/месяца в локальном timezone и отправляет ISO. Backend валидирует range. Отдельная timezone settings отложена.

### 7. Permissions и privacy

Trainer:

- `finance:manage_settings`;
- `finance:read_own`;
- `finance:mark_paid`;
- `finance:record_expense`;
- `finance:adjust_own`.

Student:

- `finance:read_own_charge` — только charge собственных Session.

Ни один student endpoint не раскрывает общий доход, расходы или чужие долги тренера.

### 8. Client scope

Flutter:

- trainer `/finance`: summary presets, debts, ledger, mark paid, add expense, settings;
- session card shows price/payment state;
- no-show dialog asks «Списать стоимость?»;
- student sees only own price/status.

Web:

- `/finance`: period controls, summary cards, debts, ledger table, expense/settings forms;
- sessions support mark-paid and explicit no-show billing decision.

### 9. Existing data migration

До deployment нет надёжной historical price. Поэтому:

- новые bookings после migration require settings and create charge;
- существующие Sessions не получают выдуманную цену автоматически;
- nullable relation/payment summary означает `not_tracked` для legacy Session;
- отдельный backfill UI/command отложен.

## Risks / Trade-offs

- [Trainer не настроил цену, student booking блокируется] → Mobile/web показывают actionable message; trainer finance settings — первый шаг.
- [Legacy sessions без charge] → Явный `not_tracked`, без фиктивного нуля.
- [Timezone влияет на day/week] → Клиент передаёт точные UTC boundaries; timezone profile позже.
- [Bigint JSON] → Contract использует decimal string и общий formatter.
- [Mark-paid race создаёт duplicate income] → Unique index на ledger source `(source_type, source_id, type)` + transaction/lock.
- [No-show API меняется] → Flutter и web обновляются атомарно с backend; Postman/tests фиксируют body.
- [Append-only сложнее редактирования] → Корректировки сохраняют auditability и правильную статистику.

## Migration Plan

1. Migration: finance settings, session charges, ledger entries + indexes/checks.
2. Permissions seed.
3. Backend settings/booking/lifecycle/finance API + tests.
4. Flutter finance flow.
5. Web finance flow.
6. Docs + smoke with future and legacy sessions.

Rollback до production data: revert migration. После появления entries rollback требует export/backup; destructive downgrade не выполнять автоматически.

## Open Questions

Нет блокирующих. Принято для MVP:

- одна валюта `RUB`;
- full payment only;
- no_show решение делает тренер;
- manual income отсутствует, expense/adjustment доступны;
- legacy sessions = `not_tracked`.
