import 'package:equatable/equatable.dart';

import '../../data/finance_models.dart';

enum FinanceStatus { initial, loading, ready, failure }

enum FinancePeriod { day, week, month, custom }

class FinanceState extends Equatable {
  const FinanceState({
    this.status = FinanceStatus.initial,
    this.period = FinancePeriod.month,
    required this.from,
    required this.to,
    this.settings,
    this.summary,
    this.debts = const [],
    this.ledger = const [],
    this.ledgerType,
    this.error,
    this.actionInProgress = false,
  });

  final FinanceStatus status;
  final FinancePeriod period;
  final DateTime from;
  final DateTime to;
  final FinanceSettings? settings;
  final FinanceSummary? summary;
  final List<FinanceDebt> debts;
  final List<FinanceLedgerEntry> ledger;
  final String? ledgerType;
  final String? error;
  final bool actionInProgress;

  FinanceState copyWith({
    FinanceStatus? status,
    FinancePeriod? period,
    DateTime? from,
    DateTime? to,
    FinanceSettings? settings,
    bool clearSettings = false,
    FinanceSummary? summary,
    List<FinanceDebt>? debts,
    List<FinanceLedgerEntry>? ledger,
    String? ledgerType,
    bool clearLedgerType = false,
    String? error,
    bool clearError = false,
    bool? actionInProgress,
  }) {
    return FinanceState(
      status: status ?? this.status,
      period: period ?? this.period,
      from: from ?? this.from,
      to: to ?? this.to,
      settings: clearSettings ? null : settings ?? this.settings,
      summary: summary ?? this.summary,
      debts: debts ?? this.debts,
      ledger: ledger ?? this.ledger,
      ledgerType: clearLedgerType ? null : ledgerType ?? this.ledgerType,
      error: clearError ? null : error ?? this.error,
      actionInProgress: actionInProgress ?? this.actionInProgress,
    );
  }

  @override
  List<Object?> get props => [
    status,
    period,
    from,
    to,
    settings,
    summary,
    debts,
    ledger,
    ledgerType,
    error,
    actionInProgress,
  ];
}
