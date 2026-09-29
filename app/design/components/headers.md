# Component: Headers & Hero

Реф: `crops/05_header_hero.png`, `crops/04_hero_illustration.png`, `crops/02_typography_hero.png`

## Screen header (контентный)

```
Title line (28–32 Bold)          [optional illust]
Subtitle (14 muted, 1–2 lines)
```

- Title: `#2E2E2E`, можно **одно слово** `#166246` или `#57CEA8`
- Subtitle: `#2E2E2E` @ 60%, line height 1.4
- Illustration: справа, 80–120px — optional; без ассета оставить whitespace или простую geometric shape mint

## Accent word pattern

`Text.rich` / `TextSpan`:

```
Enter Your  +  Measurements(#166246, Bold)
Move Better. Live  +  Stronger.(#57CEA8)
```

Для бренда: `Fitness` + `Yoda`(#166246) на login.

## Section label (ref_02)

Малый badge `01` в круге primary + UPPERCASE label — опционально для настроек / about. Не для MVP форм.

## Decorative background

- Soft mint circle за иллюстрацией (opacity low)
- Dot grid — skip в MVP (шум)
- Wave между hero и формой — nice-to-have CustomPainter; MVP: просто цвет canvas
