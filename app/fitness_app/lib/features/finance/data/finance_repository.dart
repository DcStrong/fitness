import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'finance_models.dart';

class FinanceRepository {
  FinanceRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<FinanceSettings?> getSettings() async {
    try {
      final response = await _dio.get<dynamic>('/finance/settings');
      if (response.data == null) return null;
      return FinanceSettings.fromJson(jsonMap(response.data));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw _map(error);
    }
  }

  Future<FinanceSettings> updateSettings(String priceMinor) async {
    try {
      final response = await _dio.put<dynamic>(
        '/finance/settings',
        data: {'defaultSessionPriceMinor': priceMinor, 'currency': 'RUB'},
      );
      return FinanceSettings.fromJson(jsonMap(response.data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<FinanceSummary> getSummary(DateTime from, DateTime to) async {
    try {
      final response = await _dio.get<dynamic>(
        '/finance/summary',
        queryParameters: _range(from, to),
      );
      return FinanceSummary.fromJson(jsonMap(response.data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<List<FinanceLedgerEntry>> getLedger(
    DateTime from,
    DateTime to, {
    String? type,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/finance/ledger',
        queryParameters: {..._range(from, to), 'type': ?type},
      );
      return _list(response.data).map(FinanceLedgerEntry.fromJson).toList();
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<List<FinanceDebt>> getDebts() async {
    try {
      final response = await _dio.get<dynamic>('/finance/debts');
      return _list(response.data).map(FinanceDebt.fromJson).toList();
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<void> markPaid(
    String chargeId, {
    required String paymentMethod,
    DateTime? paidAt,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/finance/charges/$chargeId/mark-paid',
        data: {
          'paymentMethod': paymentMethod,
          if (paidAt != null) 'paidAt': paidAt.toUtc().toIso8601String(),
        },
      );
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<void> addExpense({
    required String amountMinor,
    String? category,
    String? note,
    DateTime? occurredAt,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/finance/expenses',
        data: {
          'amountMinor': amountMinor,
          if (category != null && category.isNotEmpty) 'category': category,
          if (note != null && note.isNotEmpty) 'note': note,
          if (occurredAt != null)
            'occurredAt': occurredAt.toUtc().toIso8601String(),
        },
      );
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<void> reverseLedgerEntry(String entryId, {String? note}) async {
    try {
      await _dio.post<dynamic>(
        '/finance/ledger/$entryId/reverse',
        data: {if (note != null && note.isNotEmpty) 'note': note},
      );
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Map<String, String> _range(DateTime from, DateTime to) => {
    'from': from.toUtc().toIso8601String(),
    'to': to.toUtc().toIso8601String(),
  };

  List<Map<String, dynamic>> _list(dynamic data) {
    final source = data is Map
        ? (data['items'] ?? data['entries'] ?? data['debts'])
        : data;
    if (source is! List) return const [];
    return source.whereType<Map>().map(jsonMap).toList();
  }

  ApiException _map(DioException error) {
    final data = error.response?.data;
    var message = 'Ошибка сети';
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    }
    return ApiException(message, statusCode: error.response?.statusCode);
  }
}
