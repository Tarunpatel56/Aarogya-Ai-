class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;
  final String? code;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.details,
    this.code,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidationError => statusCode == 400 || statusCode == 422;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => message;
}
