# Mapping: Ref → Fitness Yoda

## Берём (must)

| Из рефа | В Yoda |
|---------|--------|
| Палитра 5 цветов + canvas | `AppColors` / `ColorScheme` |
| Stadium primary button + arrow | все главные CTA |
| White soft cards | списки слотов, сессий, инвайтов, relationships |
| Input-in-card | login/register, create slot forms |
| Bottom nav pill active | app shell (после auth) |
| Accent word в заголовках | brand + screen titles |
| Мятный info banner | ошибки? нет — tips / empty hints |

## Адаптируем (translate)

| Реф-фича | Yoda-смысл |
|----------|------------|
| Choose Workout cards | Home quick actions (расписание, инвайт, история) |
| BMI metric card | «Ближайшая тренировка» / счётчик open slots |
| Measurements onboarding | Register + выбор роли trainer/student |
| Floating measure icons | можно игнорировать |
| Profile testimonial card | empty state «пригласите первого ученика» |

## Отбрасываем (out of MVP scope)

- Nutrition / macros tracking  
- BMI calculator как продукт  
- Anatomical muscle illustrations  
- FitTrack branding / marketing copy  
- 5-step health onboarding  

## Экран → реф-якорь

| Экран приложения | Смотреть |
|------------------|----------|
| Login | `ref_login.png` — hero + белая auth-панель + поля + CTA |
| Register | `ref_login.png` как композиция + ref_04 для выбора роли |
| Home | ref_05 selection cards + header |
| Coach slots / student book | cards + primary CTA (ref_05/03) |
| Sessions list / history | nutrition-style list rows внутри white card (ref_01 left) |
| Invite create / accept | form like ref_04 |
| App shell tabs | ref_05 bottom nav |

## Текущий код

- Тема: `app/fitness_app/lib/app/theme/app_theme.dart` (сейчас seed `0xFF0F766E`)
- Экраны: Material default ListTile / AppBar — будут рескиниться после tokens + components
- Логику Bloc/API **не** трогать в дизайн-промптах без нужды

## Auth reference: `ref_login.png`

Используем как главный визуальный якорь для Login:

- верхний hero-блок примерно 40–42% экрана: логотип, название, короткий слоган, wellness-иллюстрация;
- нижняя белая панель с верхними радиусами 24–28;
- приветственный заголовок и подпись по центру;
- outline-поля email/password с leading icon и toggle visibility;
- primary stadium-кнопка `Войти`;
- ссылка на регистрацию внизу.

Не переносим функции, которых пока нет в продуктовых контрактах:

- Google Sign-In;
- восстановление пароля;
- разделитель `OR`.

Иллюстрацию и чужой бренд FitTrack не копируем. Для первой итерации допустим фирменный абстрактный wellness-hero без нового ассета; финальную иллюстрацию добавлять отдельно.
