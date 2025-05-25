import 'dart:io';

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

    test('from() method converts FormatException to missingCredentials', () {
      final formatException = FormatException('Invalid format');
      final authException = AuthException.from(formatException);

      expect(authException.type, equals(AuthExceptionType.missingCredentials));
      expect(authException.error, equals(formatException));
    });

    test('from() method converts network exceptions correctly', () {
      final socketException = SocketException('Connection failed');
      final authException = AuthException.from(socketException);

      expect(authException.type, equals(AuthExceptionType.networkError));
      expect(authException.error, equals(socketException));
    });

    test('all exception types are distinguishable in switch statements', () {
      // This test ensures we can pattern match on all enum values
      void handleException(AuthException e) {
        var handled = false;

        switch (e.type) {
          case AuthExceptionType.invalidCredentials:
            handled = true;
            break;
          case AuthExceptionType.missingCredentials:
            handled = true;
            break;
          case AuthExceptionType.providerError:
            handled = true;
            break;
          case AuthExceptionType.networkError:
            handled = true;
            break;
          case AuthExceptionType.serverError:
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
