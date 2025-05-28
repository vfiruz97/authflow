import 'package:authflow/authflow.dart';
import 'package:flutter_test/flutter_test.dart';

class MockStorage implements AuthStorage {
  AuthToken? _token;
  AuthUser? _user;

  @override
  Future<void> clearAll() async {
    _token = null;
    _user = null;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }

  @override
  Future<void> clearUser() async {
    _user = null;
  }

  @override
  Future<AuthToken?> getToken() async {
    return _token;
  }

  @override
  Future<AuthUser?> getUser() async {
    return _user;
  }

  @override
  Future<void> saveToken(AuthToken token) async {
    _token = token;
  }

  @override
  Future<void> saveUser(AuthUser user) async {
    _user = user;
  }
}

void main() {
  setUpAll(() {
    AuthManager.enableTestMode();
    AuthEventBus.enableTestMode();
  });

  tearDownAll(() {
    AuthManager.disableTestMode();
    AuthEventBus.disableTestMode();
  });

  group('AuthManager', () {
    late AuthManager authManager;
    late MockStorage mockStorage;
    late AnonymousAuthProvider anonymousProvider;

    setUp(() {
      // Create a new AuthManager instance for each test
      authManager = AuthManager();
      mockStorage = MockStorage();
      anonymousProvider = AnonymousAuthProvider();

      // Register the provider
      AuthRegistry().register(anonymousProvider);
    });

    tearDown(() {
      // Clean up after each test
      AuthRegistry().clear();
    });

    test('configure sets up AuthManager with storage', () async {
      await authManager.configure(AuthConfig(providers: [anonymousProvider], storage: mockStorage));

      expect(authManager.status, equals(AuthStatus.unauthenticated));
    });

    test('login with provider sets authenticated state', () async {
      await authManager.configure(AuthConfig(providers: [anonymousProvider], storage: mockStorage));

      final result = await authManager.loginWithProvider(anonymousProvider.providerId, {});

      expect(authManager.status, equals(AuthStatus.authenticated));
      expect(authManager.currentUser, isNotNull);
      expect(authManager.currentToken, isNotNull);
      expect(authManager.currentProviderId, equals(anonymousProvider.providerId));

      // Verify result contains user and token
      expect(result.user, equals(authManager.currentUser));
      expect(result.token, equals(authManager.currentToken));
    });

    test('logout clears the session', () async {
      await authManager.configure(AuthConfig(providers: [anonymousProvider], storage: mockStorage));

      await authManager.loginWithProvider(anonymousProvider.providerId, {});
      await authManager.logout();

      expect(authManager.status, equals(AuthStatus.unauthenticated));
      expect(authManager.currentUser, isNull);
      expect(authManager.currentToken, isNull);
      expect(authManager.currentProviderId, isNull);
    });

    test('setSession directly sets an authenticated session', () async {
      await authManager.configure(AuthConfig(providers: [anonymousProvider], storage: mockStorage));

      final user = DefaultAuthUser(id: 'test-user-id', email: 'test@example.com');

      final token = AuthToken(accessToken: 'test-token', expiresAt: DateTime.now().add(const Duration(days: 1)));

      await authManager.setSession(user, token, providerId: 'direct');

      expect(authManager.status, equals(AuthStatus.authenticated));
      expect(authManager.currentUser, equals(user));
      expect(authManager.currentToken, equals(token));
      expect(authManager.currentProviderId, equals('direct'));
    });

    test('isAuthenticated returns correct authentication state', () async {
      await authManager.configure(AuthConfig(providers: [anonymousProvider], storage: mockStorage));

      expect(authManager.isAuthenticated, isFalse);

      await authManager.loginWithProvider(anonymousProvider.providerId, {});

      expect(authManager.isAuthenticated, isTrue);

      await authManager.logout();

      expect(authManager.isAuthenticated, isFalse);
    });

    test('login fails with appropriate exception when provider not found', () async {
      await authManager.configure(AuthConfig(providers: [], storage: mockStorage));

      expect(
        () => authManager.loginWithProvider('nonexistent_provider', {}),
        throwsA(isA<AuthException>().having((e) => e.type, 'exception type', AuthExceptionType.provider)),
      );
    });

    test('login fails with appropriate exception when no providers registered', () async {
      // Clear the registry
      AuthRegistry().clear();
      await authManager.configure(AuthConfig(providers: [], storage: mockStorage));

      expect(
        () => authManager.login({}),
        throwsA(isA<AuthException>().having((e) => e.type, 'exception type', AuthExceptionType.provider)),
      );
    });

    test('streams emit correct values on login and logout', () async {
      // Configure first
      await authManager.configure(AuthConfig(providers: [anonymousProvider], storage: mockStorage));

      final statusValues = <AuthStatus>[];
      final userValues = <AuthUser?>[];
      final tokenValues = <AuthToken?>[];
      final providerIdValues = <String?>[];

      // Then listen
      final statusSub = authManager.statusStream.listen(statusValues.add);
      final userSub = authManager.userStream.listen(userValues.add);
      final tokenSub = authManager.tokenStream.listen(tokenValues.add);
      final providerIdSub = authManager.providerIdStream.listen(providerIdValues.add);

      await authManager.loginWithProvider(anonymousProvider.providerId, {});
      await authManager.logout();

      await Future.delayed(const Duration(milliseconds: 100)); // Increased delay
      await statusSub.cancel();
      await userSub.cancel();
      await tokenSub.cancel();
      await providerIdSub.cancel();

      // The expected sequence for status: unauthenticated (initial), loading, authenticated, loading, unauthenticated
      expect(
        statusValues,
        equals([
          AuthStatus.unauthenticated,
          AuthStatus.loading,
          AuthStatus.authenticated,
          AuthStatus.loading,
          AuthStatus.unauthenticated,
        ]),
        reason: "Status stream should emit 5 distinct values in sequence.",
      );

      // Revised expectations for userValues, tokenValues, providerIdValues (should be 3 items due to distinct())
      expect(
        userValues.length,
        3,
        reason: "userValues should have 3 items: initial (null), login (user), logout (null)",
      );
      expect(userValues[0], isNull, reason: "Initial user should be null after configure.");
      expect(userValues[1], isA<AuthUser>(), reason: "User should be an AuthUser after login.");
      expect(userValues[2], isNull, reason: "User should be null after logout.");

      expect(
        tokenValues.length,
        3,
        reason: "tokenValues should have 3 items: initial (null), login (token), logout (null)",
      );
      expect(tokenValues[0], isNull, reason: "Initial token should be null after configure.");
      expect(tokenValues[1], isA<AuthToken>(), reason: "Token should be an AuthToken after login.");
      expect(tokenValues[2], isNull, reason: "Token should be null after logout.");

      expect(
        providerIdValues.length,
        3,
        reason: "providerIdValues should have 3 items: initial (null), login (id), logout (null)",
      );
      expect(providerIdValues[0], isNull, reason: "Initial providerId should be null after configure.");
      expect(providerIdValues[1], equals(anonymousProvider.providerId), reason: "ProviderId should match after login.");
      expect(providerIdValues[2], isNull, reason: "ProviderId should be null after logout.");
    });

    test('event bus dispatches login and logout events (global)', () async {
      // 1. Enable test mode for AuthEventBus.
      AuthEventBus.disableTestMode();

      // 2. Create AuthManager. It should pick up the test-specific AuthEventBus.
      //    Re-initialize authManager from setUp to ensure it's fresh for this test's specific EventBus context.
      authManager = AuthManager();
      await authManager.configure(AuthConfig(providers: [anonymousProvider], storage: mockStorage));

      final events = <AuthEvent>[];

      // 3. Listen to events using the same test-specific AuthEventBus instance.
      final sub = AuthEventBus().events.listen(events.add);

      // 4. Perform actions.
      await authManager.loginWithProvider(anonymousProvider.providerId, {});
      await authManager.logout();

      await Future.delayed(const Duration(milliseconds: 100));
      await sub.cancel();

      // 5. Assertions.
      expect(events.whereType<LoginEvent>(), isNotEmpty, reason: "Should have received a LoginEvent.");
      expect(events.whereType<LogoutEvent>(), isNotEmpty, reason: "Should have received a LogoutEvent.");

      // 6. Disable test mode for AuthEventBus.
      AuthEventBus.disableTestMode();
    });

    test('reset clears state and registry', () async {
      await authManager.configure(AuthConfig(providers: [anonymousProvider], storage: mockStorage));
      await authManager.loginWithProvider(anonymousProvider.providerId, {});
      authManager.reset();
      expect(authManager.status, AuthStatus.unauthenticated);
      expect(authManager.currentUser, isNull);
      expect(authManager.currentToken, isNull);
      expect(authManager.currentProviderId, isNull);
      expect(AuthRegistry().providers, isEmpty);
    });

    test('dispose closes all streams (public API)', () async {
      await authManager.configure(AuthConfig(providers: [anonymousProvider], storage: mockStorage));
      authManager.dispose();
      // After dispose, listening to streams returns the last value and then closes
      final statusEvents = <AuthStatus>[];
      final sub = authManager.statusStream.listen(statusEvents.add);
      await Future.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      expect(statusEvents, equals([AuthStatus.unauthenticated]));
    });

    test('restores session from storage if valid', () async {
      final user = DefaultAuthUser(id: 'restore-id', email: 'restore@example.com');
      final token = AuthToken(accessToken: 'restore-token', expiresAt: DateTime.now().add(const Duration(days: 1)));
      mockStorage._user = user;
      mockStorage._token = token;
      await authManager.configure(AuthConfig(providers: [anonymousProvider], storage: mockStorage));
      expect(authManager.status, AuthStatus.authenticated);
      expect(authManager.currentUser, equals(user));
      expect(authManager.currentToken, equals(token));
    });

    test('restores session fails if token expired', () async {
      final user = DefaultAuthUser(id: 'restore-id', email: 'restore@example.com');
      final token = AuthToken(
        accessToken: 'restore-token',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      mockStorage._user = user;
      mockStorage._token = token;
      await authManager.configure(AuthConfig(providers: [anonymousProvider], storage: mockStorage));
      expect(authManager.status, AuthStatus.unauthenticated);
      expect(authManager.currentUser, isNull);
      expect(authManager.currentToken, isNull);
    });

    test('restores session fails if provider checkSession returns false', () async {
      final user = DefaultAuthUser(id: 'restore-id', email: 'restore@example.com');
      final token = AuthToken(accessToken: 'restore-token', expiresAt: DateTime.now().add(const Duration(days: 1)));
      mockStorage._user = user;
      mockStorage._token = token;
      // Custom provider that always fails checkSession
      final badProvider = _BadProvider();
      AuthRegistry().register(badProvider);
      await authManager.configure(AuthConfig(providers: [badProvider], storage: mockStorage));
      expect(authManager.status, AuthStatus.unauthenticated);
      expect(authManager.currentUser, isNull);
      expect(authManager.currentToken, isNull);
    });

    test('can switch between multiple providers', () async {
      AuthEventBus.enableTestMode();
      authManager = AuthManager(); // re-create to use fresh event bus
      final provider2 = AnonymousAuthProvider();
      AuthRegistry().register(provider2);
      await authManager.configure(AuthConfig(providers: [anonymousProvider, provider2], storage: mockStorage));
      final result1 = await authManager.loginWithProvider(anonymousProvider.providerId, {});
      expect(authManager.currentProviderId, anonymousProvider.providerId);
      final result2 = await authManager.loginWithProvider(provider2.providerId, {});
      expect(authManager.currentProviderId, provider2.providerId);
      expect(result2.user, isNot(equals(result1.user)));
      AuthEventBus.disableTestMode();
    });
  });
}

// Helper bad provider for session restore test
class _BadProvider extends AnonymousAuthProvider {
  @override
  Future<bool> checkSession(AuthToken token, AuthUser user) async => false;
}
