import 'package:fitness_app/features/more/presentation/more_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finance row is shown only with the finance permission', () {
    List<String> routes(bool canReadFinance) => [
      for (final section in trainerMoreSections(canReadFinance: canReadFinance))
        for (final item in section) item.route,
    ];

    expect(routes(true), contains('/finance'));
    expect(routes(false), isNot(contains('/finance')));
  });

  test('rows owned by other tabs switch tabs instead of stacking', () {
    final items = trainerMoreSections(
      canReadFinance: true,
    ).expand((section) => section);

    expect(
      items.where((item) => item.switchesTab).map((item) => item.route),
      unorderedEquals(['/schedule/recurring', '/invite']),
    );
  });
}
