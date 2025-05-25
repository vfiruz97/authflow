import 'package:authflow/authflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthException', () {
    test('custom exception type works as expected', () {
      const customMessage = 'Custom authentication error';
      final details = {'errorCode': 'E123', 'action': 'verify_email'};

      final exception = AuthException.custom(customMessage, error: Exception('Original error'), details: details);

      expect(exception.type, equals(AuthExceptionType.custom));
      expect(exception.message, equals(customMessage));
      expect(exception.details, equals(details));
      expect(exception.error, isNotNull);
    });

    test('from() static method passes through an existing AuthException', () {
      final original = AuthException.credentials('Test credentials error');
      final result = AuthException.from(original);

      expect(result, equals(original));
    });

    test('from() static method converts any error to unknown type', () {
      final randomError = Exception('Random error');
      final authException = AuthException.from(randomError);

      expect(authException.type, equals(AuthExceptionType.unknown));
      expect(authException.error, equals(randomError));
    });

    test('all exception types are distinguishable in switch statements', () {
      // This test ensures we can pattern match on all enum values
      void handleException(AuthException e) {
        var handled = false;

        switch (e.type) {
          case AuthExceptionType.credentials:
            handled = true;
            break;
          case AuthExceptionType.provider:
            handled = true;
            break;
          case AuthExceptionType.custom:
            handled = true;
            break;
          case AuthExceptionType.unknown:
            handled = true;
            break;
        }

        expect(handled, isTrue, reason: 'Exception type ${e.type} was not handled');
      }

      // Test with a custom exception
      handleException(AuthException.custom('Test'));
    });
  });
}
