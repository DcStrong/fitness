import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('switches themes without framework exceptions', (tester) async {
    final themeMode = ValueNotifier(ThemeMode.light);
    addTearDown(themeMode.dispose);

    await tester.pumpWidget(_ThemeSwitchHarness(themeMode: themeMode));

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(themeMode.value, ThemeMode.dark);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(themeMode.value, ThemeMode.light);
    expect(tester.takeException(), isNull);
  });
}

class _ThemeSwitchHarness extends StatelessWidget {
  const _ThemeSwitchHarness({required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        themeAnimationDuration: Duration.zero,
        home: Scaffold(
          body: Column(
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeMode,
                builder: (context, currentMode, _) {
                  return SwitchListTile(
                    title: const Text('Тема'),
                    value: currentMode == ThemeMode.dark,
                    onChanged: (isDark) {
                      final nextMode = isDark
                          ? ThemeMode.dark
                          : ThemeMode.light;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        themeMode.value = nextMode;
                      });
                    },
                  );
                },
              ),
              FilledButton(onPressed: () {}, child: const Text('Dev action')),
            ],
          ),
        ),
      ),
    );
  }
}
