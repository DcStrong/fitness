# Component: Inputs

Реф: `crops/04_input_cards.png`, `crops/03_input_row_cards.png`

## Паттерн A — Field inside white card (предпочтительный для Yoda форм)

```
┌─────────────────────────────────────────────┐
│ [■ icon]  Enter Your Weight (Kg)      [Kg]  │
└─────────────────────────────────────────────┘
```

| Element | Spec |
|---------|------|
| Card | white, radius 16, soft shadow, height ~56–64 |
| Leading icon tile | 40×40, bg `#166246`, icon white, radius 10 |
| Label / value | `#2E2E2E`, 14–16 |
| Unit chip | bg mintSoft / pale green, radius 8–10, text `#166246` |
| Focus | subtle border primary 1.5 или усиление shadow |

В рефе часто **underline** под числом внутри карточки. Для email/password удобнее:

- сохранить card-обёртку + icon tile  
- внутри: стандартный `TextField` без outline (border: InputBorder.none)  
- или одна нижняя линия `UnderlineInputBorder`

## Паттерн B — Compact twin cards (Age / Weight)

Две карточки в Row. Для Yoda: редко нужно; можно для «дата / время» слота.

## Auth forms (адаптация)

Login / Register:

1. Canvas `#F1F7F5`
2. Brand title с accent word
3. 2–3 input cards (email, password, role)
4. Primary stadium «Войти»
5. Text button «Создать аккаунт»

Не использовать filled grey Material inputs из текущего `AppTheme` без переработки — они конфликтуют с рефом.

## Validation / error

- Текст ошибки под карточкой, `#C62828`, 12
- Карточка: border error 1.5 или красный icon tile (осторожно — не перекричать primary)
