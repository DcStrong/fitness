import 'package:equatable/equatable.dart';

Map<String, dynamic> jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Ожидался JSON-объект');
}

String decimalString(dynamic value, {String fallback = '0'}) {
  if (value is String && RegExp(r'^-?\d+$').hasMatch(value)) return value;
  if (value is int) return value.toString();
  return fallback;
}

class MoneyAmount extends Equatable {
  const MoneyAmount({required this.amountMinor, required this.currency});

  factory MoneyAmount.fromJson(Map<String, dynamic> json) => MoneyAmount(
    amountMinor: decimalString(json['amountMinor']),
    currency: json['currency'] as String? ?? 'RUB',
  );

  final String amountMinor;
  final String currency;

  @override
  List<Object?> get props => [amountMinor, currency];
}

class FinanceSettings extends Equatable {
  const FinanceSettings({
    required this.defaultSessionPriceMinor,
    required this.currency,
    this.updatedAt,
  });

  factory FinanceSettings.fromJson(Map<String, dynamic> json) =>
      FinanceSettings(
        defaultSessionPriceMinor: decimalString(
          json['defaultSessionPriceMinor'],
        ),
        currency: json['currency'] as String? ?? 'RUB',
        updatedAt: json['updatedAt'] as String?,
      );

  final String defaultSessionPriceMinor;
  final String currency;
  final String? updatedAt;

  @override
  List<Object?> get props => [defaultSessionPriceMinor, currency, updatedAt];
}

class FinanceCounts extends Equatable {
  const FinanceCounts({
    this.completed = 0,
    this.noShowChargeable = 0,
    this.paid = 0,
    this.outstanding = 0,
  });

  factory FinanceCounts.fromJson(Map<String, dynamic> json) => FinanceCounts(
    completed: (json['completed'] as num?)?.toInt() ?? 0,
    noShowChargeable:
        (json['noShowChargeable'] as num?)?.toInt() ??
        (json['no_show_chargeable'] as num?)?.toInt() ??
        0,
    paid: (json['paid'] as num?)?.toInt() ?? 0,
    outstanding: (json['outstanding'] as num?)?.toInt() ?? 0,
  );

  final int completed;
  final int noShowChargeable;
  final int paid;
  final int outstanding;

  @override
  List<Object?> get props => [completed, noShowChargeable, paid, outstanding];
}

class FinanceSummary extends Equatable {
  const FinanceSummary({
    required this.currency,
    required this.accruedMinor,
    required this.receivedMinor,
    required this.outstandingMinor,
    required this.expensesMinor,
    required this.adjustmentsMinor,
    required this.netMinor,
    required this.counts,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) => FinanceSummary(
    currency: json['currency'] as String? ?? 'RUB',
    accruedMinor: decimalString(json['accruedMinor']),
    receivedMinor: decimalString(json['receivedMinor']),
    outstandingMinor: decimalString(json['outstandingMinor']),
    expensesMinor: decimalString(json['expensesMinor']),
    adjustmentsMinor: decimalString(json['adjustmentsMinor']),
    netMinor: decimalString(json['netMinor']),
    counts: FinanceCounts.fromJson(
      json['counts'] is Map ? jsonMap(json['counts']) : json,
    ),
  );

  final String currency;
  final String accruedMinor;
  final String receivedMinor;
  final String outstandingMinor;
  final String expensesMinor;
  final String adjustmentsMinor;
  final String netMinor;
  final FinanceCounts counts;

  @override
  List<Object?> get props => [
    currency,
    accruedMinor,
    receivedMinor,
    outstandingMinor,
    expensesMinor,
    adjustmentsMinor,
    netMinor,
    counts,
  ];
}

class SessionFinance extends Equatable {
  const SessionFinance({
    required this.status,
    this.chargeId,
    this.amountMinor,
    this.currency,
    this.earnedAt,
    this.paidAt,
    this.paymentMethod,
  });

  factory SessionFinance.fromJson(Map<String, dynamic> json) => SessionFinance(
    status: json['status'] as String? ?? 'not_tracked',
    chargeId: json['chargeId'] as String?,
    amountMinor: json['amountMinor'] == null
        ? null
        : decimalString(json['amountMinor']),
    currency: json['currency'] as String?,
    earnedAt: json['earnedAt'] as String?,
    paidAt: json['paidAt'] as String?,
    paymentMethod: json['paymentMethod'] as String?,
  );

  final String status;
  final String? chargeId;
  final String? amountMinor;
  final String? currency;
  final String? earnedAt;
  final String? paidAt;
  final String? paymentMethod;

  bool get isTracked => status != 'not_tracked' && amountMinor != null;
  bool get canMarkPaid =>
      status == 'pending' && earnedAt != null && chargeId != null;

  @override
  List<Object?> get props => [
    status,
    chargeId,
    amountMinor,
    currency,
    earnedAt,
    paidAt,
    paymentMethod,
  ];
}

class FinanceDebt extends Equatable {
  const FinanceDebt({
    required this.chargeId,
    required this.amountMinor,
    required this.currency,
    this.sessionId,
    this.studentId,
    this.studentEmail,
    this.studentDisplayName,
    this.earnedAt,
  });

  factory FinanceDebt.fromJson(Map<String, dynamic> json) {
    final charge = json['charge'] is Map ? jsonMap(json['charge']) : json;
    return FinanceDebt(
      chargeId:
          charge['chargeId'] as String? ??
          charge['id'] as String? ??
          json['chargeId'] as String? ??
          '',
      amountMinor: decimalString(charge['amountMinor']),
      currency: charge['currency'] as String? ?? 'RUB',
      sessionId: charge['sessionId'] as String? ?? json['sessionId'] as String?,
      studentId: charge['studentId'] as String? ?? json['studentId'] as String?,
      studentEmail:
          charge['studentEmail'] as String? ?? json['studentEmail'] as String?,
      studentDisplayName:
          charge['studentDisplayName'] as String? ??
          json['studentDisplayName'] as String?,
      earnedAt: charge['earnedAt'] as String?,
    );
  }

  final String chargeId;
  final String amountMinor;
  final String currency;
  final String? sessionId;
  final String? studentId;
  final String? studentEmail;
  final String? studentDisplayName;
  final String? earnedAt;

  @override
  List<Object?> get props => [
    chargeId,
    amountMinor,
    currency,
    sessionId,
    studentId,
    studentEmail,
    studentDisplayName,
    earnedAt,
  ];
}

class FinanceLedgerEntry extends Equatable {
  const FinanceLedgerEntry({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.occurredAt,
    this.category,
    this.note,
    this.reversesEntryId,
  });

  factory FinanceLedgerEntry.fromJson(Map<String, dynamic> json) =>
      FinanceLedgerEntry(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'adjustment',
        amountMinor: decimalString(json['amountMinor']),
        currency: json['currency'] as String? ?? 'RUB',
        occurredAt:
            json['occurredAt'] as String? ??
            json['createdAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
        category: json['category'] as String?,
        note: json['note'] as String?,
        reversesEntryId: json['reversesEntryId'] as String?,
      );

  final String id;
  final String type;
  final String amountMinor;
  final String currency;
  final String occurredAt;
  final String? category;
  final String? note;
  final String? reversesEntryId;

  @override
  List<Object?> get props => [
    id,
    type,
    amountMinor,
    currency,
    occurredAt,
    category,
    note,
    reversesEntryId,
  ];
}
