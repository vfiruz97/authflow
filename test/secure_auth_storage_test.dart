import 'package:authflow/authflow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SecureAuthStorage', () {
    late SecureAuthStorage storage;

    setUp(() async {
      // Setup SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      // Create storage with default user deserializer
      storage = SecureAuthStorage.withDefaultUser();
    });

    test('saveToken and getToken handle token persistence', () async {
      // Create a test token
      final token = AuthToken(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      // Save the token
      await storage.saveToken(token);

      // Retrieve the token
      final retrievedToken = await storage.getToken();

      // Verify
      expect(retrievedToken, isNotNull);
      expect(retrievedToken!.accessToken, equals(token.accessToken));
      expect(retrievedToken.refreshToken, equals(token.refreshToken));
      expect(retrievedToken.expiresAt?.toIso8601String(), equals(token.expiresAt?.toIso8601String()));
    });

    test('saveUser and getUser handle user persistence', () async {
      // Create a test user
      final user = DefaultAuthUser(id: 'test-user-id', email: 'test@example.com', displayName: 'Test User');

      // Save the user
      await storage.saveUser(user);

      // Retrieve the user
      final retrievedUser = await storage.getUser();

      // Verify
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.id, equals(user.id));
      expect(retrievedUser.email, equals(user.email));
      expect(retrievedUser.displayName, equals(user.displayName));
    });

    test('clearToken removes the token', () async {
      // Create and save a test token
      final token = AuthToken(accessToken: 'test-token');
      await storage.saveToken(token);

      // Verify token was saved
      expect(await storage.getToken(), isNotNull);

      // Clear the token
      await storage.clearToken();

      // Verify token was cleared
      expect(await storage.getToken(), isNull);
    });

    test('clearUser removes the user', () async {
      // Create and save a test user
      final user = DefaultAuthUser(id: 'test-user-id');
      await storage.saveUser(user);

      // Verify user was saved
      expect(await storage.getUser(), isNotNull);

      // Clear the user
      await storage.clearUser();

      // Verify user was cleared
      expect(await storage.getUser(), isNull);
    });

    test('clearAll removes both user and token', () async {
      // Create and save a test user and token
      final user = DefaultAuthUser(id: 'test-user-id');
      final token = AuthToken(accessToken: 'test-token');

      await storage.saveUser(user);
      await storage.saveToken(token);

      // Verify both were saved
      expect(await storage.getUser(), isNotNull);
      expect(await storage.getToken(), isNotNull);

      // Clear all
      await storage.clearAll();

      // Verify both were cleared
      expect(await storage.getUser(), isNull);
      expect(await storage.getToken(), isNull);
    });

    test('custom user deserializer is used', () async {
      // Create a custom storage with a custom deserializer
      final customStorage = SecureAuthStorage(
        userDeserializer: (data) {
          // Create a user with a suffix to demonstrate custom deserialization
          final defaultUser = DefaultAuthUser.deserialize(data);
          return DefaultAuthUser(
            id: '${defaultUser.id}-custom',
            email: defaultUser.email,
            displayName: defaultUser.displayName,
          );
        },
      );

      // Create and save a test user
      final user = DefaultAuthUser(id: 'test-user-id', email: 'test@example.com');

      await customStorage.saveUser(user);

      // Retrieve the user with custom deserializer
      final retrievedUser = await customStorage.getUser();

      // Verify custom deserializer was used
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.id, equals('${user.id}-custom'));
      expect(retrievedUser.email, equals(user.email));
    });
  });
}
