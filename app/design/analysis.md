# Analysis — референсы глазами дизайнера

Пять кадров = один продукт-вайб (FitTrack / wellness), не пять разных систем.

## ref_login — основной Login reference

**Что видно:** вертикальный экран с wellness hero в верхней части и белой auth-панелью с крупными верхними радиусами.

**Забрать:**
- пропорцию hero / form примерно 40 / 60;
- бренд и короткий слоган над иллюстрацией;
- белую панель как отдельный foreground-layer;
- центрированный welcome title + subtitle;
- outline email/password fields с line icons и visibility toggle;
- один deep-green stadium CTA;
- спокойную ссылку на регистрацию внизу.

**Не копировать:**
- FitTrack logo/name, бегуна и английский слоган;
- Google Sign-In, password recovery и `OR`, пока их нет в продуктовых контрактах;
- фиксированную высоту макета: Flutter-версия должна скроллиться при клавиатуре.

## ref_01 — Showcase board

**Что видно:** телефон с onboarding-иллюстрацией + две data-cards (nutrition, BMI).

**Забрать:**
- Иллюстрация как hero (мотивация), не UI-хром
- Floating circular icon buttons на белом круге с тенью
- Карточки: белые, radius ~20, мягкая тень, плотная типографика метрик
- Info banner внутри карточки: mint soft bg + «i» icon

**Не тащить в Yoda MVP:** nutrition macros, BMI как продукт (можно позже в «профиль здоровья»).

## ref_02 — Marketing / About

**Что видно:** типографика + feature icon row + большой profile/testimonial card.

**Забрать:**
- Акцент цветом внутри фразы (`Stronger.` → mint)
- Короткая зелёная underline под заголовком
- Icon tiles: белый squircle + line icon primary + label под ним
- Large rounded card с mint panel (для empty states / coach intro — опционально)

**Не тащить:** маркетинговый «About this project», чужой бренд FitTrack.

## ref_03 — BMI Checker (полный экран + tab bar)

**Самый полезный экран для системы компонентов.**

**Забрать:**
- Canvas не белый — светло-мятный → белые карточки «всплывают»
- Input cards: icon tile + label + underline field (не outline box)
- Primary stadium button full-width + trailing arrow
- Bottom nav: icon-only inactive / pill+label active
- Result card: circular gauge + big metric (паттерн для «статус слота / сессии»)

## ref_04 — Measurements onboarding

**Забрать:**
- Вертикальный ритм: hero illustration → title (accent word) → body → input cards → dots → CTA
- Input row: `[green icon tile] label … [unit chip Kg/Cm]`
- Pagination dots (onboarding / multi-step)
- CTA sticky-ish внизу на белой «подложке»

**Адаптация Yoda:** экран регистрации / выбора роли (trainer|student) в том же ритме.

## ref_05 — Choose Workout + nav

**Забрать:**
- Header: title + subtitle + small illustration справа
- Large selection cards с CTA внутри карточки («Get Started»)
- Bottom nav active pill (лучшая нарезка: `crops/05_bottom_nav.png`)

**Адаптация Yoda:** выбор действия на home (расписание / приглашения / занятия) теми же selection cards вместо сырого ListTile.

---

## Общий визуальный язык (синтез)

1. **Мятный воздух** — фон canvas, много whitespace  
2. **Белые острова** — cards = главный контейнер контента  
3. **Deep green CTA** — один главный акцент действия на экран  
4. **Capsule everything interactive** — buttons + active tab  
5. **Friendly radius** — 16–24, не «enterprise 8»  
6. **Иллюстрации** — опциональный слой; MVP может стартовать без них (геометрия + иконки)

## Анти-паттерны (не копировать из AI-дефолтов)

- Фиолетовые градиенты, neon glow  
- Карточки в hero ради декора  
- Pill-clusters статистики на первом экране  
- Тёмный mode как default (реф — light; dark можно позже)
