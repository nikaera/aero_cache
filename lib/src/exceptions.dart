/// Base exception class for all AeroCache operations
class AeroCacheException implements Exception {
  /// Create a new AeroCacheException
  const AeroCacheException(this.message, [this.originalException]);

  /// Error message
  final String message;

  /// Original exception that caused this error
  final Object? originalException;

  @override
  String toString() {
    const prefix = 'AeroCacheException';
    if (originalException != null) {
      return '$prefix: $message (Original: $originalException)';
    }
    return '$prefix: $message';
  }
}

/// Exception thrown when network operations fail
class NetworkException extends AeroCacheException {
  /// Create a new NetworkException
  const NetworkException(super.message, [super.originalException])
      : url = null,
        statusCode = null;

  /// Create a NetworkException with URL and status code
  const NetworkException.withDetails(
    super.message,
    this.url,
    this.statusCode, [
    super.originalException,
  ]);

  /// The URL that failed to load
  final String? url;

  /// HTTP status code if available
  final int? statusCode;

  @override
  String toString() {
    const prefix = 'NetworkException';
    final details = <String>[
      if (url != null) 'URL: $url',
      if (statusCode != null) 'Status Code: $statusCode',
    ].join(', ');
    if (originalException != null) {
      return '$prefix: $message (Original: $originalException${details.isNotEmpty ? ', $details' : ''})';
    }
    return '$prefix: $message${details.isNotEmpty ? ' ($details)' : ''}';
  }
}

/// Exception thrown when storage operations fail
class StorageException extends AeroCacheException {
  /// Create a new StorageException
  const StorageException(super.message, [super.originalException])
      : filePath = null;

  /// Create a StorageException with file path
  const StorageException.withPath(
    super.message,
    this.filePath, [
    super.originalException,
  ]);

  /// The file path that caused the error
  final String? filePath;

  @override
  String toString() {
    const prefix = 'StorageException';
    if (originalException != null) {
      return '$prefix: $message (Original: $originalException)';
    }
    return '$prefix: $message';
  }
}

/// Exception thrown when compression/decompression fails
class CompressionException extends AeroCacheException {
  /// Create a new CompressionException
  const CompressionException(super.message, [super.originalException])
      : algorithm = null;

  /// Create a CompressionException with algorithm details
  const CompressionException.withAlgorithm(
    super.message,
    this.algorithm, [
    super.originalException,
  ]);

  /// The compression algorithm that failed
  final String? algorithm;

  @override
  String toString() {
    const prefix = 'CompressionException';
    if (originalException != null) {
      return '$prefix: $message (Original: $originalException)';
    }
    return '$prefix: $message';
  }
}

/// Exception thrown when validation fails
class ValidationException extends AeroCacheException {
  /// Create a new ValidationException
  const ValidationException(super.message, [super.originalException])
      : field = null,
        value = null;

  /// Create a ValidationException with field and value details
  const ValidationException.withDetails(
    super.message,
    this.field,
    this.value, [
    super.originalException,
  ]);

  /// The field that failed validation
  final String? field;

  /// The value that failed validation
  final Object? value;

  @override
  String toString() {
    const prefix = 'ValidationException';
    if (originalException != null) {
      return '$prefix: $message (Original: $originalException)';
    }
    return '$prefix: $message';
  }
}

/// Exception thrown when cache initialization fails
class InitializationException extends AeroCacheException {
  /// Create a new InitializationException
  const InitializationException(super.message, [super.originalException]);

  @override
  String toString() {
    const prefix = 'InitializationException';
    if (originalException != null) {
      return '$prefix: $message (Original: $originalException)';
    }
    return '$prefix: $message';
  }
}

/// Exception thrown when cache serialization/deserialization fails
class SerializationException extends AeroCacheException {
  /// Create a new SerializationException
  const SerializationException(super.message, [super.originalException])
      : dataType = null;

  /// Create a SerializationException with data type
  const SerializationException.withDataType(
    super.message,
    this.dataType, [
    super.originalException,
  ]);

  /// The data type that failed serialization
  final String? dataType;

  @override
  String toString() {
    const prefix = 'SerializationException';
    if (originalException != null) {
      return '$prefix: $message (Original: $originalException)';
    }
    return '$prefix: $message';
  }
}
