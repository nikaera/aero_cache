/// Exception thrown by AeroCache operations
class AeroCacheException implements Exception {
  /// Create a new AeroCacheException
  AeroCacheException(this.message, [this.originalException]);

  /// Error message
  final String message;

  /// Original exception that caused this error
  final dynamic originalException;

  @override
  String toString() {
    final prefix = 'AeroCacheException: $message';
    if (originalException != null) {
      return '$prefix (Original: $originalException)';
    }
    return prefix;
  }
}
