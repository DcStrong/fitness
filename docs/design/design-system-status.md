# Дизайн-система Fitness Yoda — статус внедрения

> Источник правды по дизайну — каталог [`app/design/`](../../app/design/): токены, спеки
> компонентов, нарезки референсов и пошаговые промпты внедрения. Этот файл — только
> **сводка статусов**: что из дизайн-пака уже в коде, а что осталось.
>
> Post-MVP волны (A–D) и очередь OpenSpec — в [`docs/roadmap/plan.md`](../roadmap/plan.md)
> (§ Post-MVP: Design polish).
>
> Макеты продуктовых экранов (календарь, доступность) — в [`docs/assets/`](../assets/).

## Что где лежит

| Артефакт | Путь | Назначение |
|---|---|---|
| Обзор + порядок внедрения | `app/design/README.md` | 6 этапов, производные токены |
| Токены | `app/design/tokens.md` | цвет, radius, spacing, тени, типографика, motion |
| Разбор референсов | `app/design/analysis.md` | что берём / не копируем из каждого рефа |
| Маппинг на продукт | `app/design/mapping-fitness-yoda.md` | экран → реф-якорь, что вне scope |
| Спеки компонентов | `app/design/components/` | `buttons` `cards` `inputs` `navigation` `headers` |
| Промпты внедрения | `app/design/prompts/01…06` | по одному промпту на этап, самодостаточны |
| Референсы | `app/design/ref_01…05.png`, `ref_login.png` | `ref_login.png` — главный якорь экрана входа |
| Нарезки | `app/design/crops/` | визуальные якоря для каждого компонента |

Палитра-основа: `#166246` (акцент/CTA), `#FFFFFF` (карточки), `#2E2E2E` (текст),
`#6F9E8F`, `#57CEA8` (mint). Реализована в `app/fitness_app/lib/app/theme/app_colors.dart`.

## Этапы плана внедрения

Выполнялись как OpenSpec change `apply-fitness-yoda-design-system`
(архив: `openspec/changes/archive/2026-07-18-apply-fitness-yoda-design-system/`, 34/34 задачи).

| # | Этап | Промпт | Статус |
|---|---|---|---|
| 1 | Theme tokens | `01-theme-tokens.md` | ✅ `AppColors` + `AppTheme.light()` по токенам |
| 2 | Buttons | `02-buttons.md` | ✅ `FyButton` / `FyPrimaryButton` (stadium, loading, disabled) |
| 3 | Cards + inputs | `03-cards-inputs.md` | ✅ `FyCard`, `FyInputCard`, `InputDecorationTheme` |
| 4 | Navigation shell | `04-navigation-shell.md` | ✅ `StatefulShellRoute` + mint active pill, роли trainer/student |
| 5 | Auth screens | `05-auth-screens.md` | ✅ Login по `ref_login.png` (hero + белая панель), Register в той же системе |
| 6 | Home + schedule | `06-home-schedule.md` | ✅ quick-action cards на Home, soft cards в слотах/сессиях, `FyInfoBanner` |

## Осталось из дизайн-пака

Всё ниже описано в дизайн-паке, но сознательно отложено или не доведено.
Волны A–D — см. [roadmap](../roadmap/plan.md#post-mvp-design-polish).

| Пункт | Где описано | Статус | Волна | Комментарий |
|---|---|---|---|---|
| Фирменный шрифт (Plus Jakarta Sans) | `tokens.md` §Типографика | ✅ волна A | **A** | `google_fonts` + `AppTheme.light()`; Manrope не берём |
| Dark theme по токенам | `prompts/01` п.3 | ⚠️ заглушка | **C** | `AppTheme.dark()` — `ColorScheme.fromSeed`; `ThemeMode` жёстко `light` |
| `FySecondaryButton` (outlined stadium) | `components/buttons.md` | ✅ волна A | **A** | Wrapper над `FyButton.secondary` |
| Фирменная hero-иллюстрация | `mapping-fitness-yoda.md` §Auth | ✅ волна B | **B** | `assets/images/brand/fy-auth-hero.png` + mint décor в `AuthScreenLayout` |
| Floating circular icon buttons | `components/buttons.md` | ❌ не сделано | **D** | Parked («MVP: можно отложить») |
| Metric card с circular gauge | `components/cards.md` | ❌ не сделано | **D** | Ждёт `trainer-stats-dashboard` |
| Compact twin cards (Паттерн B) | `components/inputs.md` | ❌ не сделано | **D** | После стабилизации book/free-time |
| Pagination dots | `components/navigation.md` | ❌ не сделано | **D** | Нужны при onboarding-флоу |
| Кастомный top bar | `components/headers.md` | ✅ волна B | **B** | `FyTopBar` (title + subtitle; без bell) на authenticated shell |
| Section label badge `01` в круге | `components/headers.md` | ❌ не сделано | **D** | Не для форм |
| Декоративный фон (mint circle, wave) | `components/headers.md` | ✅ волна B | **B** | Auth hero circles + wave painter; `dot grid` — skip |
| Motion: press scale 0.98, fade+slide табов | `tokens.md` §Motion | ✅ волна B | **B** | CTA press, shell tab, auth panel entrance, calendar day switch |

## Долг, накопленный после внедрения

Экраны, добавленные позже дизайн-change'а (календарь, доступность, регулярные записи),
частично разошлись с системой. **Волна A (`polish-mobile-design-system`) закрывает этот долг.**

| Место | Проблема | Волна |
|---|---|---|
| `widgets/calendar_event_card.dart` | → `FyCard` + `FyChip` | **A** ✅ |
| `screens/recurring_booking_detail_page.dart` | → `FySecondaryButton` | **A** ✅ |
| weekday / day pickers, week type counts | → `FyChip` | **A** ✅ |
| `core/widgets/` | barrel `widgets.dart` | **A** ✅ |
| create / slot / free-time sheets | → `showFyBottomSheet` | **A** ✅ |

## Правило поддержки

Новые UI-экраны собирать из `core/widgets` (`FyButton`, `FyPrimaryButton`,
`FySecondaryButton`, `FyCard`, `FyChip`, `FyInputCard`, `FyInfoBanner`,
`FyTopBar`, `showFyDatePicker`, `showFyBottomSheet`; barrel — `widgets.dart`). Если нужного
примитива нет — сначала добавить его в `core/widgets` и описать в
`app/design/components/`, потом использовать, а не верстать локально в фиче.
