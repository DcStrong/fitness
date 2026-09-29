# Prompt 05 — Auth screens

Скопируй целиком в Agent:

---

Рескин **Login / Register**. Главный якорь Login — `app/design/ref_login.png`: wellness hero сверху и белая auth-панель снизу.

## Прочитай

- `app/design/components/headers.md`
- `app/design/components/buttons.md`
- `app/design/components/inputs.md`
- `app/design/mapping-fitness-yoda.md` (раздел Auth reference)
- `app/design/ref_login.png` — основной Login reference
- `app/design/analysis.md` (ref_04 — дополнительный якорь Register)
- `app/design/crops/04_hero_illustration.png` (опционально — без ассета не блокируйся)
- `app/design/crops/04_button_next.png`
- `login_screen.dart`, `register_screen.dart`

## Сделай

1. Login: верхний hero 40–42% высоты → белая нижняя панель с радиусами 24–28 → welcome title/subtitle → поля → primary CTA → signup link.
2. Hero: бренд `Fitness Yoda`, короткий русский слоган, зелёная wellness-композиция. Не копировать FitTrack branding; без готового фирменного ассета использовать спокойный абстрактный фон/иконку, не случайную stock-иллюстрацию.
3. Поля email/password: outline-поверхность, leading line icon; у password сохранить кнопку показать/скрыть пароль и доступную semantic label.
4. Использовать уже созданные `FyPrimaryButton` и общие input-примитивы, адаптируя их к auth reference без локального дублирования стилей.
5. Не показывать `OR`, Google Sign-In и «Забыли пароль?», пока соответствующих продуктовых контрактов нет.
6. Register: та же композиционная система; выбор роли trainer/student — twin selection chips/cards в палитре, не raw dropdown если легко заменить.
7. На компактной высоте/клавиатуре экран должен скроллиться без overflow; CTA и поля остаются доступны.
8. Без смены API полей и AuthCubit контракта.

## Не делай

- Копирование FitTrack-логотипа, бегуна и чужого слогана.
- Новые auth-функции только потому, что они показаны в референсе.
- Bottom nav на auth routes.

## Done

- [ ] Login повторяет композицию `ref_login.png`, но с брендом и функциями Fitness Yoda
- [ ] Register визуально принадлежит той же системе
- [ ] Нет overflow при открытой клавиатуре и на компактной высоте
- [ ] Analyze clean
