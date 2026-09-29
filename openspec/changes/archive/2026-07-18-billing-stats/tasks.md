## 1. Persistence & permissions

- [x] 1.1 Add billing domain interfaces under `src/billing/interface/` (money strings, charge/ledger/status/payment-method/summary types)
- [x] 1.2 Add `CoachFinanceSettings`, `SessionCharge`, and append-only `FinanceLedgerEntry` entities; register repositories/modules
- [x] 1.3 Add TypeORM migration with checks, 1:1 Session charge, ledger source idempotency, owner/range indexes
- [x] 1.4 Extend permission constants + seed for trainer finance management and student own-charge read
- [x] 1.5 Run migration + seed locally; verify legacy Sessions remain valid without fabricated charges

## 2. Price settings & booking integration

- [x] 2.1 Implement `GET/PUT /finance/settings` with positive minor-unit amount and `RUB`
- [x] 2.2 Include configured price in linked-coach open-slot responses
- [x] 2.3 Extend booking params/DTO for optional trainer price override (student cannot override)
- [x] 2.4 Atomically create Session charge snapshot during booking; reject new booking when price is not configured
- [x] 2.5 Add scoped finance summary (`pending|paid|cancelled|not_tracked`) to Session responses

## 3. Lifecycle, payments & ledger

- [x] 3.1 Update complete/cancel transitions to atomically earn/cancel tracked charges
- [x] 3.2 Change no-show API to require `{ charge: boolean }`; update Postman and clients
- [x] 3.3 Implement mark-paid transaction with method/paidAt and exactly-one linked income ledger entry
- [x] 3.4 Implement manual expense append endpoint
- [x] 3.5 Implement append-only reversal/adjustment endpoint; prohibit ledger mutation/deletion
- [x] 3.6 Add charge/ledger authorization and trainer/student resource ownership checks

## 4. Finance queries & tests

- [x] 4.1 Implement `GET /finance/summary?from&to` with accrued/received/outstanding/expenses/adjustments/net/counts
- [x] 4.2 Implement filtered `GET /finance/ledger` and `GET /finance/debts`
- [x] 4.3 Unit-test minor-unit calculations, period boundaries, net formula, and no-show policy
- [x] 4.4 Integration/API smoke: settings → book snapshot → complete/no-show → mark paid → expense → summary; verify student privacy and legacy `not_tracked`

## 5. Flutter mobile

- [x] 5.1 Add finance models/repository and decimal-string money formatter
- [x] 5.2 Add trainer finance settings, period summary, debts/ledger, mark-paid, and expense UI (RU)
- [x] 5.3 Update Session cards/actions with price/payment state and explicit no-show charge dialog
- [x] 5.4 Show student only own Session price/payment state
- [x] 5.5 Register authenticated finance routes/home entry; run Dart format/analyze and trainer+student smoke

## 6. Web console

- [x] 6.1 Upgrade vulnerable `next@15.1.0` / `eslint-config-next` to patched compatible versions; run audit/build
- [x] 6.2 Add `/finance` navigation/page with period summary cards, debts, and ledger filters
- [x] 6.3 Add finance settings, mark-paid, expense, and reversal controls
- [x] 6.4 Update web Session actions with price/payment state and explicit no-show charge decision
- [x] 6.5 Run production build and trainer/student browser smoke against local API

## 7. Documentation

- [x] 7.1 Add `docs/domain/billing.md` documenting no payment processing, money units, charge/ledger/status rules, stats semantics, and no-show policy
- [x] 7.2 Update `docs/domain/entities.md`, `docs/domain/processes.md`, and roadmap terminology to “финансовый учёт”
