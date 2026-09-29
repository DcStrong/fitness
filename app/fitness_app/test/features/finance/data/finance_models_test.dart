import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses tracked and legacy session finance variants', () {
    final tracked = SessionFinance.fromJson(const {
      'chargeId': 'charge-1',
      'status': 'pending',
      'amountMinor': '150000',
      'currency': 'RUB',
      'earnedAt': '2026-07-18T10:00:00.000Z',
      'paidAt': null,
      'paymentMethod': null,
    });
    final legacy = SessionFinance.fromJson(const {'status': 'not_tracked'});

    expect(tracked.isTracked, isTrue);
    expect(tracked.canMarkPaid, isTrue);
    expect(legacy.isTracked, isFalse);
  });

  test('keeps large money values as decimal strings', () {
    final summary = FinanceSummary.fromJson(const {
      'currency': 'RUB',
      'accruedMinor': '9007199254740993',
      'receivedMinor': '0',
      'outstandingMinor': '9007199254740993',
      'expensesMinor': '0',
      'adjustmentsMinor': '0',
      'netMinor': '0',
      'counts': {'outstanding': 1},
    });

    expect(summary.accruedMinor, '9007199254740993');
    expect(summary.counts.outstanding, 1);
  });
}
