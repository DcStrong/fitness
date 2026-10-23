import 'package:fitness_app/features/schedule/presentation/screens/sessions_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('upcoming sessions are grouped by today, this week and later', () {
    final wednesday = DateTime(2026, 10, 21, 9);
    expect(
      sessionListSection(DateTime(2026, 10, 21, 18), wednesday),
      'Сегодня',
    );
    expect(
      sessionListSection(DateTime(2026, 10, 23, 10), wednesday),
      'На этой неделе',
    );
    expect(
      sessionListSection(DateTime(2026, 10, 25, 10), wednesday),
      'На этой неделе',
    );
    expect(sessionListSection(DateTime(2026, 10, 26, 10), wednesday), 'Позже');
  });
}
