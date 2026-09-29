# Design Tokens — Fitness Yoda (from ref)

Источник: `ref_01`…`ref_05` + палитра пользователя. Числа — **целевые** для Flutter (logical px), не pixel-perfect dump.

## Color

```dart
// Предлагаемые константы (имя для AppColors / ColorScheme)
static const primary        = Color(0xFF166246); // кнопки, CTA, key accents
static const onPrimary      = Color(0xFFFFFFFF);
static const surface        = Color(0xFFFFFFFF); // карточки
static const canvas         = Color(0xFFF1F7F5); // scaffold / page bg
static const textPrimary    = Color(0xFF2E2E2E);
static const secondary      = Color(0xFF6F9E8F);
static const mint           = Color(0xFF57CEA8);
static const mintSoft       = Color(0x2957CEA8); // ~16% mint — pill / banners
static const textMuted      = Color(0x992E2E2E); // ~60%
static const iconInactive   = Color(0xFF9AA8A2);
static const success        = primary;           // MVP: тот же green
static const error          = Color(0xFFC62828); // не из рефа — оставить системный
```

### ColorScheme mapping (M3)

| Role | Value |
|------|-------|
| `primary` | `#166246` |
| `onPrimary` | `#FFFFFF` |
| `secondary` | `#6F9E8F` |
| `tertiary` | `#57CEA8` |
| `surface` | `#FFFFFF` |
| `surfaceContainerLowest` / scaffold | `#F1F7F5` |
| `onSurface` | `#2E2E2E` |
| `outlineVariant` | secondary @ ~30% |

**Не** использовать `ColorScheme.fromSeed` как единственный источник — seed размоет `#166246`. Задать `ColorScheme` явно (или seed + override primary/secondary/surface).

## Radius

| Token | Value | Где |
|-------|-------|-----|
| `radius.sm` | 12 | chips, unit badges (Kg/Cm) |
| `radius.md` | 16 | input cards, small tiles |
| `radius.lg` | 20–24 | content cards (workout, BMI) |
| `radius.xl` | 28–32 | крупные hero cards (ref_02) |
| `radius.pill` | 999 | primary buttons, nav active pill |

Реф = **дружелюбный soft UI**, не «острые» Material 12 везде. Кнопки — stadium (полная капсула).

## Spacing

| Token | Value |
|-------|-------|
| page horizontal | 24 |
| card padding | 16–20 |
| stack gap (карточки) | 12–16 |
| section gap | 24–32 |
| button height large | 54 | forms / auth CTA (`FyButtonSize.large`) |
| button height medium | 44 | dense card actions (`FyButtonSize.medium`) |
| icon tile | 40×40 (внутри 36–44) |

## Elevation / Shadow

Карточки **не** с Material elevation 2 «серой грязью». Реф:

```text
color: #000000 @ 0.06–0.10
blur: 16–24
offset: (0, 4–8)
spread: 0
```

Белая карточка на canvas `#F1F7F5` читается даже без тени; тень — лёгкая.

## Typography

Стиль рефа: современный grotesk / geometric sans. Для Flutter MVP:

- Рекомендация: **Plus Jakarta Sans** или **Manrope** (Google Fonts) — не Inter/Roboto «по умолчанию», если ставите бренд.
- Fallback: системный SF/Roboto ок для первой итерации токенов, шрифт можно вторым шагом.

| Style | Size / Weight | Color |
|-------|---------------|-------|
| Display / screen title | 28–32 / Bold | textPrimary; **одно** слово можно primary или mint |
| Title (card) | 18–20 / SemiBold–Bold | textPrimary |
| Body | 14–16 / Regular | textPrimary / textMuted |
| Label / overline | 11–12 / Medium, often UPPER | textMuted |
| Button | 16 / SemiBold | onPrimary |
| Metric (BMI-like) | 28–36 / Bold | primary |

Паттерн рефа: в заголовке **цветной акцент на ключевом слове**  
`Enter Your` (`#2E2E2E`) + `Measurements` (`#166246`).

## Iconography

- Outline / line icons, stroke ~1.5–2  
- Active: `#166246`  
- Inactive (tab): `#9AA8A2`  
- Icon-on-primary tile: белая иконка на `#166246` rounded square 40×40, radius 10–12  

## Motion (позже)

Реф статичен. Для приложения достаточно:

- 200–250ms ease на press scale кнопки (0.98)
- fade+slide 250ms при смене tab  
Не добавлять glow / particle / «AI purple».
