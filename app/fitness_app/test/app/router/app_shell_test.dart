import 'package:fitness_app/app/router/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appShellDestinationsForRoles', () {
    test('uses trainer destinations and invite route', () {
      final destinations = appShellDestinationsForRoles(const ['trainer']);

      expect(destinations.map((destination) => destination.branchIndex), [
        0,
        1,
        0,
        2,
        3,
      ]);
      expect(destinations.map((destination) => destination.label), [
        'Главная',
        'Расписание',
        'Тренировки',
        'Ученики',
        'Профиль',
      ]);
      expect(destinations[0].location, '/home');
      expect(destinations[1].location, '/schedule');
      expect(destinations[2].location, '/plans');
      expect(destinations[2].activePathPrefixes, ['/plans', '/tags']);
      expect(destinations[3].location, '/session-packages');
      expect(destinations[4].location, '/profile');
    });

    test('uses student social destinations', () {
      final destinations = appShellDestinationsForRoles(const ['student']);

      expect(destinations.map((destination) => destination.label), [
        'Тренеры',
        'Тренировки',
        'Мои заявки',
        'Профиль',
      ]);
      expect(destinations.map((destination) => destination.branchIndex), [
        2,
        1,
        1,
        3,
      ]);
      expect(destinations[0].location, '/trainers');
      expect(destinations[1].location, '/sessions');
      expect(destinations[2].location, '/booking-requests/mine');
    });
  });

  group('appShellSelectedIndex', () {
    test('selects schedule branch for trainer calendar routes', () {
      final destinations = appShellDestinationsForRoles(const ['trainer']);

      expect(
        appShellSelectedIndex(
          destinations: destinations,
          currentBranchIndex: 1,
          currentLocation: '/schedule',
        ),
        1,
      );
    });

    test('home tab stays home after visiting workouts and students', () {
      final destinations = appShellDestinationsForRoles(const ['trainer']);

      expect(
        appShellSelectedIndex(
          destinations: destinations,
          currentBranchIndex: 0,
          currentLocation: '/home',
        ),
        0,
      );
      expect(
        appShellSelectedIndex(
          destinations: destinations,
          currentBranchIndex: 0,
          currentLocation: '/plans',
        ),
        2,
      );
      expect(
        appShellSelectedIndex(
          destinations: destinations,
          currentBranchIndex: 2,
          currentLocation: '/session-packages',
        ),
        3,
      );
    });

    test('selects student requests and keeps sessions distinct', () {
      final destinations = appShellDestinationsForRoles(const ['student']);

      expect(
        appShellSelectedIndex(
          destinations: destinations,
          currentBranchIndex: 1,
          currentLocation: '/booking-requests/mine',
        ),
        2,
      );
      expect(
        appShellSelectedIndex(
          destinations: destinations,
          currentBranchIndex: 1,
          currentLocation: '/sessions',
        ),
        1,
      );
    });

    test('highlights trainer workouts tab for plans and tags', () {
      final destinations = appShellDestinationsForRoles(const ['trainer']);

      expect(
        appShellSelectedIndex(
          destinations: destinations,
          currentBranchIndex: 0,
          currentLocation: '/plans',
        ),
        2,
      );
      expect(
        appShellSelectedIndex(
          destinations: destinations,
          currentBranchIndex: 0,
          currentLocation: '/tags',
        ),
        2,
      );
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
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
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
