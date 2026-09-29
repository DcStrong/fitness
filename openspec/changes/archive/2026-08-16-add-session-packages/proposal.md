## Why

Слои A/B/C и календарный UX закрыты: тренер закрепляет график и проводит занятия, но лимита «абонемент на N занятий» нет — `RecurringBooking` бессрочный до отмены, остаток никто не считает. Тренеру приходится помнить вручную, у кого пакет исчерпан. Это Post-MVP Product #1 в roadmap: счётчик занятий поверх существующей pay-per-session модели без эквайринга.

## What Changes

- Добавить сущность **SessionPackage** (абонемент): тренер выдаёт связанному ученику пакет из N занятий, опциональный срок действия, статусы active / exhausted / expired / archived.
- Счётчик **осталось N** уменьшается по правилам списания (решение в design: completed vs booked; no_show / cancel).
- Привязка пакета к паре trainer↔student; занятия из **RecurringBooking** и разовые **Session** списывают один активный пакет пары (если есть).
- API: создать / прочитать / продлить (добавить занятия ± срок) / архивировать; сигнал исчерпания тренеру (in-app; push вне scope).
- Flutter (минимальный UX): остаток у тренера и ученика — список связей + detail / home, без polish волн B/C.
- `SessionCharge` и ручная оплата **сохраняются** как pay-per-session учёт; абонемент — отдельный счётчик занятий, не платёжный шлюз (взаимодействие с charge — в design).

## Non-goals

- Эквайринг, автосписание денег, предоплата через платформу.
- Несколько типов пакетов сверх «N занятий ± опциональный срок» (без безлимита, семейных, trial-продуктов).
- Design polish волн B/C; web console.
- Push/realtime уведомления (достаточно in-app сигнала при исчерпании).
- Автостоп материализации RecurringBooking при N=0 (можно показать предупреждение; жёсткая блокировка book — решение design, без перестройки sync).
- Изменение слоёв A/B/C scheduling UX сверх отображения остатка.

## Capabilities

### New Capabilities

- `session-packages-api`: HTTP API выдачи/чтения/продления/архива абонемента, счётчика «осталось N», правил списания при lifecycle Session, сигнала исчерпания.
- `mobile-session-packages`: Flutter UI (Russian) остатка у тренера и ученика — минимальные точки входа (связи / recurring detail / home по design).

### Modified Capabilities

- `session-lifecycle`: при переходах `completed` / `cancelled` / `no_show` применяется списание (или нет) к активному SessionPackage пары coach–student.
- `session-finance`: зафиксировать, что абонемент не заменяет SessionCharge/ledger; описать поведение charge для занятий, покрытых пакетом (без эквайринга).

## Impact

- Backend `backend/api/src`: entity + migration SessionPackage (+ debit ledger/audit при необходимости), service, endpoints, хуки в session lifecycle; unit + e2e.
- API `localhost:3001`: новые authenticated endpoints пакетов; существующие booking/session/finance flows без breaking changes контракта оплаты.
- Flutter `app/fitness_app`: repository + Cubit/экраны или виджеты остатка; Bloc only; без волны design polish.
- Docs: `docs/design/availability-recurring-booking.md` § add-session-packages, `docs/domain/billing.md`, roadmap Product #1.
- Зависит от archived A/B/C и `fix-recurring-session-calendar-ux`; не смешивать с polish волны B.
