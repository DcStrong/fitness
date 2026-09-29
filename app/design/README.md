# Fitness Yoda — Design Pack

Подготовка UI по референсам **без внедрения в код**. Когда будете готовы — берите промпты из `prompts/` по порядку.

## Палитра (зафиксировано)

| Hex | Роль |
|-----|------|
| `#166246` | Primary: кнопки, активные действия, акцент |
| `#FFFFFF` | Cards / surfaces (на светло-мятном фоне) |
| `#2E2E2E` | Основной текст |
| `#6F9E8F` | Secondary / muted green |
| `#57CEA8` | Highlight / mint accent (акцент в тексте, pill nav) |

Производные (для темы, не в исходной пятёрке):

| Token | Approx | Зачем |
|-------|--------|-------|
| `bg.canvas` | `#F1F7F5` | Scaffold — светло-мятный, не чистый белый |
| `bg.mintSoft` | `#57CEA8` @ 12–18% | Active nav pill, info banners |
| `text.muted` | `#2E2E2E` @ 55–65% | Подписи, secondary |
| `icon.inactive` | `#9AA8A2` | Неактивные иконки tab bar |
| `shadow.card` | black @ 6–10%, blur 16–24, y 4–8 | Мягкая «парящая» карточка |

## Структура папки

```text
app/design/
  README.md                 ← вы здесь
  tokens.md                 ← цвета, радиусы, типографика, тени
  analysis.md               ← разбор рефов глазами дизайнера
  mapping-fitness-yoda.md   ← что берём / что отбрасываем / куда маппим экраны
  components/
    buttons.md
    cards.md
    inputs.md
    navigation.md
    headers.md
  crops/                    ← нарезки компонентов из рефа
  ref_screenshot/           ← исходные скрины
  ref_login.png             ← основной референс Login
  ref_01.png … ref_05.png   ← копии с ASCII-именами
  prompts/                  ← промпты для Agent mode
    00-readme.md
    01-theme-tokens.md
    02-buttons.md
    03-cards-inputs.md
    04-navigation-shell.md
    05-auth-screens.md
    06-home-schedule.md
```

## Главный вывод (для разработчика)

Реф — **wellness / FitTrack**-стиль: soft UI, большие радиусы, stadium-кнопки, белые карточки на мятном фоне, bottom nav с **mint pill + label только у active**.

Для Fitness Yoda это **язык UI**, не копипаста фич (BMI / nutrition / workout plans из рефа не нужны в MVP). Берём компоненты и атмосферу → накладываем на auth, home, invitations, schedule.

Текущий код уже имеет `lib/app/theme/app_theme.dart` (seed teal) — внедрение = замена токенов + точечный рескин экранов, не rewrite.

## Порядок внедрения (когда решите)

1. Theme tokens  
2. Buttons  
3. Cards + inputs  
4. Navigation shell  
5. Auth screens  
6. Home + schedule  

Промпты самодостаточны: каждый ссылается на `tokens.md`, `components/*` и `crops/*`.
