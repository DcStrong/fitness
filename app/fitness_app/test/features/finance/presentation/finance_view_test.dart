import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/finance/data/finance_repository.dart';
import 'package:fitness_app/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:fitness_app/features/finance/presentation/finance_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFinanceRepository extends Fake implements FinanceRepository {
  @override
  Future<FinanceSettings?> getSettings() async => null;

  @override
  Future<FinanceSummary> getSummary(DateTime from, DateTime to) async =>
      const FinanceSummary(
        currency: 'RUB',
        accruedMinor: '1800000',
        receivedMinor: '1200000',
        outstandingMinor: '600000',
        expensesMinor: '0',
        adjustmentsMinor: '0',
        netMinor: '1200000',
        counts: FinanceCounts(completed: 5, paid: 3, outstanding: 2),
      );

  @override
  Future<List<FinanceDebt>> getDebts() async => const [
    FinanceDebt(
      chargeId: 'c1',
      amountMinor: '200000',
      currency: 'RUB',
      studentEmail: 'pavel@example.com',
      studentDisplayName: 'Павел Иванов',
    ),
  ];

  @override
  Future<List<FinanceLedgerEntry>> getLedger(
    DateTime from,
    DateTime to, {
    String? type,
  }) async => const [];
}

void main() {
  testWidgets('shows received hero, key numbers and debts with pay action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider(
          create: (_) =>
              FinanceCubit(repository: _FakeFinanceRepository())..load(),
          child: const FinanceView(permissions: ['finance:mark_paid']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Получено за месяц'), findsOneWidget);
    expect(find.byKey(const Key('finance-received')), findsOneWidget);
    expect(find.text('5 занятий'), findsOneWidget);
    expect(find.text('Павел Иванов'), findsOneWidget);
    expect(find.text('Ждёт оплаты'), findsWidgets);
    expect(find.byKey(const Key('finance-pay-c1')), findsOneWidget);
    expect(find.text('За период нет операций'), findsOneWidget);
  });
}
