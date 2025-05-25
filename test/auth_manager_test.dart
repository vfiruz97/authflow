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
  });
}
