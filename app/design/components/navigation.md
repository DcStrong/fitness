# Component: Navigation

Реф: `crops/05_bottom_nav.png`, `crops/03_bottom_nav.png`

## Bottom navigation (главный chrome приложения)

| Prop | Value |
|------|-------|
| Bar bg | `#FFFFFF` |
| Top radius | 16–20 (мягкий «остров») optional |
| Height | ~64–72 + safe area |
| Items | 3–4 |
| Inactive | outline icon `#9AA8A2`, **без** label |
| Active | mintSoft pill + icon `#166246` + label mint/secondary |

```
┌────────────────────────────────────────────┐
│  ⌂    [ 🏋️ Workout ]    ◎      ☺         │
│       ↑ active pill                         │
└────────────────────────────────────────────┘
```

### Fitness Yoda IA (предложение)

| Tab | Coach | Student |
|-----|-------|---------|
| Home | главная / связи | главная / тренер |
| Schedule | слоты + сессии | запись + сессии |
| Invite / People | QR / приглашения | (скрыть или «мой тренер») |
| Profile | профиль / выход | профиль / выход |

Пока в приложении нет shell с tabs — это **целевой** chrome. До внедрения: AppBar ok.

## Top bar

Реф: back chevron + title (`crops/03_header.png`)

| Prop | Value |
|------|-------|
| bg | transparent / canvas |
| title | `#166246` или `#2E2E2E`, 18–20 Bold |
| back | circle or plain chevron `#166246` |
| trailing | optional illustration (не обязательно) |

Elevation 0, без серой Material app bar линии.

## Pagination dots (onboarding)

`crops/04_pagination_dots.png`

- Active / past: `#166246`
- Future: `#D5DED9`
- Size: 8px, gap 8
