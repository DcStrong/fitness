import 'package:fitness_app/app/router/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appShellDestinationsForRoles', () {
    test('trainer gets home, schedule, students, chats and more', () {
      final destinations = appShellDestinationsForRoles(const ['trainer']);

      expect(destinations.map((d) => d.label), [
        'Главная',
        'Расписание',
        'Ученики',
        'Чаты',
        'Ещё',
      ]);
      expect(destinations.map((d) => d.branchIndex), [0, 1, 2, 4, 3]);
      expect(destinations.map((d) => d.location), [
        '/home',
        '/schedule',
        '/session-packages',
        '/chats',
        '/more',
      ]);
    });

    test('student gets home, booking, workouts, chat and profile', () {
      final destinations = appShellDestinationsForRoles(const ['student']);

      expect(destinations.map((d) => d.label), [
        'Главная',
        'Запись',
        'Тренировки',
        'Чат',
        'Профиль',
      ]);
      expect(destinations.map((d) => d.branchIndex), [0, 1, 1, 4, 3]);
      expect(destinations.map((d) => d.location), [
        '/home',
        '/schedule/book',
        '/sessions',
        '/chats',
        '/profile',
      ]);
    });
  });

  group('appShellSelectedIndex', () {
    int selected(List<String> roles, int branch, String location) =>
        appShellSelectedIndex(
          destinations: appShellDestinationsForRoles(roles),
          currentBranchIndex: branch,
          currentLocation: location,
        );

    test('trainer schedule tab covers sessions and requests', () {
      expect(selected(const ['trainer'], 1, '/schedule'), 1);
      expect(selected(const ['trainer'], 1, '/schedule/recurring'), 1);
      expect(selected(const ['trainer'], 1, '/sessions/abc'), 1);
      expect(selected(const ['trainer'], 1, '/booking-requests/inbox'), 1);
    });

    test('trainer students tab covers student cards and invites', () {
      expect(selected(const ['trainer'], 2, '/session-packages'), 2);
      expect(selected(const ['trainer'], 2, '/students/42'), 2);
      expect(selected(const ['trainer'], 2, '/invite'), 2);
    });

    test('trainer more tab covers workouts, finance and profile', () {
      for (final location in const [
        '/more',
        '/plans',
        '/plans/1',
        '/tags',
        '/finance',
        '/profile',
        '/reviews',
      ]) {
        expect(selected(const ['trainer'], 3, location), 4, reason: location);
      }
      expect(selected(const ['trainer'], 4, '/chats'), 3);
      expect(selected(const ['trainer'], 0, '/home'), 0);
    });

    test('student booking and workouts stay distinct in one branch', () {
      expect(selected(const ['student'], 1, '/schedule/book'), 1);
      expect(selected(const ['student'], 1, '/booking-requests/mine'), 1);
      expect(selected(const ['student'], 2, '/trainers/7'), 1);
      expect(selected(const ['student'], 1, '/sessions'), 2);
      expect(selected(const ['student'], 0, '/me/training'), 2);
      expect(selected(const ['student'], 3, '/profile'), 4);
    });
  });

  for (final viewport in const [
    (name: 'compact', size: Size(320, 700)),
    (name: 'standard', size: Size(390, 844)),
  ]) {
    for (final role in const ['student', 'trainer']) {
      testWidgets('$role navigation fits ${viewport.name} viewport', (
        tester,
      ) async {
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final destinations = appShellDestinationsForRoles([role]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: NavigationBar(
                selectedIndex: 0,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  for (final destination in destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                ],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byType(NavigationDestination),
          findsNWidgets(destinations.length),
        );
      });
    }
  }
}
