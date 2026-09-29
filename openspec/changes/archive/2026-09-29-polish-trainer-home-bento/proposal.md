## Why

Главная тренера уже показывает расписание дня и feature-карточки, но визуально остаётся «скромной»: одноколоночный список «Всё необходимое», нет быстрого обзора недели и scan-метрик. Выбран **вариант C** (`mock-home-c-asymmetric-bento.png`): мини-календарь недели, stat-chips и asymmetric bento для shortcuts — ближе к hub ученика и bento-референсам, без смены API.

## What Changes

- **Мини-расписание недели** под заголовком даты: горизонтальная полоска 7 дней (пн–вс текущей недели) с подписью тренировки на днях, где есть booked session; tap дня — фильтр/фокус списка «Сегодня» или переход в `/schedule` на этот день (решение в design).
- **Stat-chips** в одну строку: «Сегодня · N», «Заявки · N» (тренер, если count известен), третий chip — «На неделе · N» или tappable «Расписание» (без нового Nest API в v1).
- **Asymmetric bento «Всё необходимое»** (тренер): высокая плитка «Расписание» слева; справа «Ученики» + «Планирование»; снизу на всю ширину «Регулярные тренировки»; «Финансы» — compact tile или вторая строка bento при `finance:read_own`.
- Сохранить: pending badge (или поглощается chip «Заявки»), QR-приглашение, collapse history/upcoming, refresh, role-aware routes.
- **Студент:** не asymmetric bento; улучшить «Всё необходимое» до **2 колонок** на phone (как уже на tablet ≥520px).

## Non-goals

- Полный day/week/month календарь на Home (остаётся `/schedule`).
- Новые Nest endpoints; счётчик «свободных слотов» только если собирается из уже доступных client/API данных без расширения контракта.
- Pixel-perfect к mock; stock-фото; новые табы shell; web console.
- Редизайн других экранов (hub, session, library).

## Capabilities

### New Capabilities

- (нет)

### Modified Capabilities

- `mobile-home-dashboard`: week mini-calendar strip, stat chips, asymmetric bento shortcuts (trainer), 2-col feature grid (student), визуальная иерархия по mock-home-c.

## Impact

- Flutter: `features/home/` (`home_view.dart`, `home_cubit.dart`, `home_state.dart`, новые widgets `home_week_strip`, `home_stat_chips`, `home_bento_shortcuts`), возможно переиспользование `CalendarDateStrip` / `calendar_period_format` из schedule.
- `HomeCubit`: расширить загрузку sessions на текущую календарную неделю (для strip), без изменения daily history logic.
- Assets: `app/design/generated/mock-home-c-asymmetric-bento.png` как якорь смысла.
- Tests: widget tests для bento layout, week strip labels, stat chips; обновить `home_view_test` при наличии.
- Backend / web: без изменений.
