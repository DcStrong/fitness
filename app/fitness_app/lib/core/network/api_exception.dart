class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.existingId});

  final String message;
  final int? statusCode;
  final String? existingId;

  @override
  String toString() => message;
}
