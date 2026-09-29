import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/finance_repository.dart';
import 'finance_state.dart';

class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit({required FinanceRepository repository})
    : _repository = repository,
      super(_initialState());

  final FinanceRepository _repository;

  static FinanceState _initialState() {
    final range = rangeFor(FinancePeriod.month, DateTime.now());
    return FinanceState(from: range.$1, to: range.$2);
  }

  static (DateTime, DateTime) rangeFor(FinancePeriod period, DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    return switch (period) {
      FinancePeriod.day => (day, day.add(const Duration(days: 1))),
      FinancePeriod.week => (
        day.subtract(Duration(days: day.weekday - DateTime.monday)),
        day
            .subtract(Duration(days: day.weekday - DateTime.monday))
            .add(const Duration(days: 7)),
      ),
      FinancePeriod.month => (
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      ),
      FinancePeriod.custom => (day, day.add(const Duration(days: 1))),
    };
  }

  Future<void> load() async {
    emit(state.copyWith(status: FinanceStatus.loading, clearError: true));
    try {
      final results = await Future.wait<dynamic>([
        _repository.getSettings(),
        _repository.getSummary(state.from, state.to),
        _repository.getDebts(),
        _repository.getLedger(state.from, state.to, type: state.ledgerType),
      ]);
      emit(
        state.copyWith(
          status: FinanceStatus.ready,
          settings: results[0],
          clearSettings: results[0] == null,
          summary: results[1],
          debts: results[2],
          ledger: results[3],
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(status: FinanceStatus.failure, error: error.toString()),
      );
    }
  }

  Future<void> selectPeriod(FinancePeriod period) async {
    if (period == FinancePeriod.custom) return;
    final range = rangeFor(period, DateTime.now());
    emit(state.copyWith(period: period, from: range.$1, to: range.$2));
    await load();
  }

  Future<void> selectCustomRange(DateTime from, DateTime inclusiveTo) async {
    emit(
      state.copyWith(
        period: FinancePeriod.custom,
        from: DateTime(from.year, from.month, from.day),
        to: DateTime(inclusiveTo.year, inclusiveTo.month, inclusiveTo.day + 1),
      ),
    );
    await load();
  }

  Future<void> filterLedger(String? type) async {
    emit(state.copyWith(ledgerType: type, clearLedgerType: type == null));
    await load();
  }

  Future<bool> saveSettings(String amountMinor) =>
      _run(() => _repository.updateSettings(amountMinor));

  Future<bool> markPaid(String chargeId, String paymentMethod) =>
      _run(() => _repository.markPaid(chargeId, paymentMethod: paymentMethod));

  Future<bool> addExpense({
    required String amountMinor,
    String? category,
    String? note,
  }) => _run(
    () => _repository.addExpense(
      amountMinor: amountMinor,
      category: category,
      note: note,
    ),
  );

  Future<bool> reverse(String entryId, {String? note}) =>
      _run(() => _repository.reverseLedgerEntry(entryId, note: note));

  Future<bool> _run(Future<dynamic> Function() action) async {
    emit(state.copyWith(actionInProgress: true, clearError: true));
    try {
      await action();
      emit(state.copyWith(actionInProgress: false));
      await load();
      return true;
    } catch (error) {
      emit(state.copyWith(actionInProgress: false, error: error.toString()));
      return false;
    }
  }
}
