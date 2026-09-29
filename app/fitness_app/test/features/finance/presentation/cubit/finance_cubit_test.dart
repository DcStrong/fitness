import 'package:fitness_app/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:fitness_app/features/finance/presentation/cubit/finance_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FinanceCubit.rangeFor', () {
    final now = DateTime(2026, 7, 18, 14, 30);

    test('uses local, end-exclusive day boundaries', () {
      final range = FinanceCubit.rangeFor(FinancePeriod.day, now);
      expect(range.$1, DateTime(2026, 7, 18));
      expect(range.$2, DateTime(2026, 7, 19));
    });

    test('uses Monday through next Monday for week', () {
      final range = FinanceCubit.rangeFor(FinancePeriod.week, now);
      expect(range.$1, DateTime(2026, 7, 13));
      expect(range.$2, DateTime(2026, 7, 20));
    });

    test('uses calendar month boundaries', () {
      final range = FinanceCubit.rangeFor(FinancePeriod.month, now);
      expect(range.$1, DateTime(2026, 7));
      expect(range.$2, DateTime(2026, 8));
    });
  });
}
