class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.existingId, this.code});

  final String message;
  final int? statusCode;
  final String? existingId;

  /// Машинный код ошибки бэкенда (например `PORTFOLIO_LIMIT_REACHED`).
  final String? code;

  @override
  String toString() => message;
}
