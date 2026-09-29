import 'package:fitness_app/features/finance/data/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyFormatter', () {
    test('formats decimal-string minor units without floating point', () {
      expect(MoneyFormatter.format('150000'), '1\u00a0500,00 ₽');
      expect(MoneyFormatter.format('-42'), '−0,42 ₽');
      expect(
        MoneyFormatter.format('900719925474099312345'),
        '9\u00a0007\u00a0199\u00a0254\u00a0740\u00a0993\u00a0123,45 ₽',
      );
    });

    test('parses ruble input into positive minor-unit string', () {
      expect(MoneyFormatter.parseRubles('1 500,25 ₽'), '150025');
      expect(MoneyFormatter.parseRubles('99'), '9900');
      expect(MoneyFormatter.parseRubles('0'), isNull);
      expect(MoneyFormatter.parseRubles('10,999'), isNull);
    });
  });
}
