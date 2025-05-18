import 'package:authflow/authflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnonymousAuthProvider', () {
    test('login creates anonymous user and token', () async {
      final provider = AnonymousAuthProvider();
      final result = await provider.login({});

      expect(result.user, isNotNull);
      expect(result.user.isAnonymous, isTrue);
      expect(result.token.accessToken, isNotNull);
      expect(result.token.expiresAt, isNotNull);
    });

    test('custom ID generator is used when provided', () async {
      const customId = 'custom-anonymous-id';
      final provider = AnonymousAuthProvider(idGenerator: () => customId);
      final result = await provider.login({});

      expect(result.user.id, equals(customId));
    });
  });

  group('AuthRegistry', () {
    tearDown(() {
      // Clear the registry after each test
      AuthRegistry().clear();
    });

    test('register adds provider to registry', () {
      final provider = AnonymousAuthProvider();
      final registry = AuthRegistry();

      registry.register(provider);

      expect(registry.hasProvider(provider.providerId), isTrue);
      expect(registry.getProvider(provider.providerId), equals(provider));
    });

    test('unregister removes provider from registry', () {
      final provider = AnonymousAuthProvider();
      final registry = AuthRegistry();

      registry.register(provider);
      final result = registry.unregister(provider.providerId);

      expect(result, isTrue);
      expect(registry.hasProvider(provider.providerId), isFalse);
    });

    test('clear removes all providers', () {
      final registry = AuthRegistry();

      registry.register(AnonymousAuthProvider());
      registry.register(MockEmailPasswordAuthProvider());

      registry.clear();

      expect(registry.providers, isEmpty);
    });
  });

  group('EmailPasswordAuthProvider', () {
    test('login validates email and password', () async {
      final provider = MockEmailPasswordAuthProvider();

      // Missing email
      expect(() => provider.login({'password': 'test123'}), throwsA(isA<FormatException>()));

      // Missing password
      expect(() => provider.login({'email': 'test@example.com'}), throwsA(isA<FormatException>()));
    });

    test('login returns user and token with valid credentials', () async {
      final provider = MockEmailPasswordAuthProvider();
      final result = await provider.login({'email': 'test@example.com', 'password': 'test123'});

      expect(result.user, isNotNull);
      expect(result.user.email, equals('test@example.com'));
      expect(result.token, isNotNull);
    });
  });
}
