import 'package:authflow/authflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthToken', () {
    test('serialization and deserialization', () {
      final token = AuthToken(
        accessToken: 'test-token',
        refreshToken: 'test-refresh',
        expiresAt: DateTime.parse('2023-12-31T23:59:59Z'),
      );

      final serialized = token.serialize();
      final deserialized = AuthToken.deserialize(serialized);

      expect(deserialized.accessToken, equals(token.accessToken));
      expect(deserialized.refreshToken, equals(token.refreshToken));
      expect(deserialized.expiresAt?.toIso8601String(), equals(token.expiresAt?.toIso8601String()));
    });

    test('isExpired returns true for expired tokens', () {
      final expiredToken = AuthToken(
        accessToken: 'test-token',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(expiredToken.isExpired, isTrue);
    });

    test('isExpired returns false for valid tokens', () {
      final validToken = AuthToken(accessToken: 'test-token', expiresAt: DateTime.now().add(const Duration(days: 1)));

      expect(validToken.isExpired, isFalse);
    });

    test('isExpired returns false for tokens without expiration', () {
      final noExpirationToken = AuthToken(accessToken: 'test-token');

      expect(noExpirationToken.isExpired, isFalse);
    });
  });

  group('DefaultAuthUser', () {
    test('serialization and deserialization', () {
      final user = DefaultAuthUser(
        id: 'user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        isAnonymous: false,
      );

      final serialized = user.serialize();
      final deserialized = DefaultAuthUser.deserialize(serialized);

      expect(deserialized.id, equals(user.id));
      expect(deserialized.email, equals(user.email));
      expect(deserialized.displayName, equals(user.displayName));
      expect(deserialized.isAnonymous, equals(user.isAnonymous));
    });
  });
}
