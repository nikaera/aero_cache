import 'package:aero_cache/src/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AeroCacheException', () {
    late String message;
    setUp(() {
      message = 'Test error message';
    });

    test('should create exception with message only', () {
      final exception = AeroCacheException(message);
      expect(exception.message, message);
      expect(exception.originalException, null);
      expect(exception.toString(), 'AeroCacheException: $message');
    });

    test('should create exception with message and original exception', () {
      final originalException = ArgumentError('Original error');
      final exception = AeroCacheException(message, originalException);
      expect(exception.message, message);
      expect(exception.originalException, originalException);
      expect(
        exception.toString(),
        'AeroCacheException: $message (Original: $originalException)',
      );
    });

    test('should handle null original exception in toString', () {
      final exception = AeroCacheException(message);
      expect(exception.toString(), 'AeroCacheException: $message');
    });

    test('should be throwable', () {
      final exception = AeroCacheException(message);
      expect(() => throw exception, throwsA(isA<AeroCacheException>()));
    });
  });
}
