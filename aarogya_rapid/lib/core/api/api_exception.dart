class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;
  final bool isNetworkError;
  final bool isConflict;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.details,
    this.isNetworkError = false,
    this.isConflict = false,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

