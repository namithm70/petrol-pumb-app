class AppException implements Exception {
  const AppException(
    this.message, {
    this.statusCode,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;

  factory AppException.network([String? message]) {
    return AppException(message ?? 'No internet connection.');
  }

  factory AppException.timeout([String? message]) {
    return AppException(message ?? 'Request timed out.');
  }

  factory AppException.unexpected([String? message, Object? cause]) {
    return AppException(message ?? 'Unexpected error.', cause: cause);
  }
}
