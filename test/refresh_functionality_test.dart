import 'package:authflow/src/auth_config.dart';
import 'package:authflow/src/auth_event_bus.dart';
import 'package:authflow/src/auth_exception.dart';
import 'package:authflow/src/auth_manager.dart';
import 'package:authflow/src/auth_provider.dart';
import 'package:authflow/src/auth_token.dart';
import 'package:authflow/src/auth_user.dart';
import 'package:authflow/src/events/auth_events.dart';
import 'package:authflow/src/providers/anonymous_auth_provider.dart';
import 'package:authflow/src/providers/email_password_auth_provider.dart';
import 'package:authflow/src/storage/secure_auth_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Token Refresh Functionality', () {
    late AuthManager authManager;
    late MockAuthStorage mockStorage;
    late AuthEventBus eventBus;

    setUp(() {
      // Enable test mode for isolated testing
      AuthManager.enableTestMode();
      // Don't enable test mode for AuthEventBus to ensure same instance is used

      authManager = AuthManager();
      mockStorage = MockAuthStorage();
      eventBus = AuthEventBus();
    });

    tearDown(() {
      AuthManager.disableTestMode();
      AuthEventBus.disableTestMode();
    });

    test('refreshSession should successfully refresh valid token', () async {
      // Setup provider with refresh support
      final provider = MockEmailPasswordAuthProvider();
      final config = AuthConfig(
        providers: [provider],
        storage: mockStorage,
        autoRefreshOnExpiry: true,
      );

      await authManager.configure(config);

      // Login first
      final result = await authManager.loginWithProvider(
        'email_password',
        {'email': 'test@example.com', 'password': 'password'},
      );

      expect(authManager.isAuthenticated, true);
      expect(authManager.currentToken, equals(result.token));

      // Refresh the session
      final refreshedToken = await authManager.refreshSession();

      expect(refreshedToken, isNotNull);
      expect(refreshedToken!.accessToken, isNot(equals(result.token.accessToken)));
      expect(refreshedToken.refreshToken, equals(result.token.refreshToken));
      expect(authManager.currentToken, equals(refreshedToken));
      expect(authManager.isAuthenticated, true);
    });

    test('refreshSession should dispatch TokenRefreshEvent on success', () async {
      final provider = MockEmailPasswordAuthProvider();
      final config = AuthConfig(
        providers: [provider],
        storage: mockStorage,
        autoRefreshOnExpiry: true,
      );

      await authManager.configure(config);

      // Login first
      await authManager.loginWithProvider(
        'email_password',
        {'email': 'test@example.com', 'password': 'password'},
      );

      // Listen for refresh events
      TokenRefreshEvent? refreshEvent;
      eventBus.events.listen((event) {
        if (event is TokenRefreshEvent) {
          refreshEvent = event;
        }
      });

      // Refresh the session
      await authManager.refreshSession();

      // Wait for events to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      expect(refreshEvent, isNotNull);
      expect(refreshEvent!.isSuccess, true);
      expect(refreshEvent!.providerId, equals('email_password'));
      expect(refreshEvent!.error, isNull);
    });

    test('refreshSession should handle provider without refresh support', () async {
      final provider = NoRefreshProvider();
      final config = AuthConfig(
        providers: [provider],
        storage: mockStorage,
        autoRefreshOnExpiry: true,
      );

      await authManager.configure(config);

      // Set a mock session manually
      final user = DefaultAuthUser(id: 'test-user');
      final token = AuthToken(
        accessToken: 'test-token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await authManager.setSession(user, token, providerId: 'no-refresh');

      // Try to refresh - should return null for unsupported providers
      final refreshedToken = await authManager.refreshSession();

      expect(refreshedToken, isNull);
      expect(authManager.isAuthenticated, true);
      expect(authManager.currentToken, equals(token));
    });

    test('refreshSession should fail when no active session', () async {
      final provider = MockEmailPasswordAuthProvider();
      final config = AuthConfig(
        providers: [provider],
        storage: mockStorage,
        autoRefreshOnExpiry: true,
      );

      await authManager.configure(config);

      // Try to refresh without active session
      expect(
        () => authManager.refreshSession(),
        throwsA(isA<AuthException>()),
      );
    });

    test('_restoreSession should auto-refresh expired tokens when enabled', () async {
      final provider = MockEmailPasswordAuthProvider();
      final config = AuthConfig(
        providers: [provider],
        storage: mockStorage,
        autoRefreshOnExpiry: true,
      );

      // Setup expired token in storage
      final user = DefaultAuthUser(id: 'test-user', email: 'test@example.com');
      final expiredToken = AuthToken(
        accessToken: 'expired-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)), // Expired
      );

      mockStorage.saveUser(user);
      mockStorage.saveToken(expiredToken);

      // Configure should automatically restore and refresh
      await authManager.configure(config);

      // Should be authenticated with new token
      expect(authManager.isAuthenticated, true);
      expect(authManager.currentToken, isNotNull);
      expect(authManager.currentToken!.accessToken, isNot(equals('expired-token')));
      expect(authManager.currentUser, equals(user));
    });

    test('_restoreSession should clear session when auto-refresh disabled and token expired', () async {
      final provider = MockEmailPasswordAuthProvider();
      final config = AuthConfig(
        providers: [provider],
        storage: mockStorage,
        autoRefreshOnExpiry: false, // Disabled
      );

      // Setup expired token in storage
      final user = DefaultAuthUser(id: 'test-user', email: 'test@example.com');
      final expiredToken = AuthToken(
        accessToken: 'expired-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)), // Expired
      );

      mockStorage.saveUser(user);
      mockStorage.saveToken(expiredToken);

      // Configure should clear expired session
      await authManager.configure(config);

      // Should be unauthenticated
      expect(authManager.isAuthenticated, false);
      expect(authManager.currentToken, isNull);
      expect(authManager.currentUser, isNull);
    });

    test('AnonymousAuthProvider should support refresh', () async {
      final provider = AnonymousAuthProvider();
      final config = AuthConfig(
        providers: [provider],
        storage: mockStorage,
        autoRefreshOnExpiry: true,
      );

      await authManager.configure(config);

      // Login anonymously
      await authManager.loginWithProvider('anonymous', {});

      expect(authManager.isAuthenticated, true);
      final originalToken = authManager.currentToken!;

      // Refresh the session
      final refreshedToken = await authManager.refreshSession();

      expect(refreshedToken, isNotNull);
      expect(refreshedToken!.accessToken, isNot(equals(originalToken.accessToken)));
      expect(authManager.currentUser!.isAnonymous, true);
    });

    test('TokenRefreshEvent.failed should be dispatched on refresh failure', () async {
      final provider = FailingRefreshProvider();
      final config = AuthConfig(
        providers: [provider],
        storage: mockStorage,
        autoRefreshOnExpiry: true,
      );

      await authManager.configure(config);

      // Set a mock session manually
      final user = DefaultAuthUser(id: 'test-user');
      final token = AuthToken(
        accessToken: 'test-token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await authManager.setSession(user, token, providerId: 'failing-refresh');

      // Listen for refresh events
      TokenRefreshEvent? refreshEvent;
      eventBus.events.listen((event) {
        if (event is TokenRefreshEvent) {
          refreshEvent = event;
        }
      });

      // Try to refresh - should fail
      expect(
        () => authManager.refreshSession(),
        throwsA(isA<AuthException>()),
      );

      // Wait for events to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      expect(refreshEvent, isNotNull);
      expect(refreshEvent!.isSuccess, false);
      expect(refreshEvent!.error, isNotNull);
    });
  });
}

/// Mock auth storage for testing
class MockAuthStorage extends SecureAuthStorage {
  AuthUser? _user;
  AuthToken? _token;

  MockAuthStorage() : super(userDeserializer: (data) => DefaultAuthUser.deserialize(data));

  @override
  Future<void> saveUser(AuthUser user) async {
    _user = user;
  }

  @override
  Future<void> saveToken(AuthToken token) async {
    _token = token;
  }

  @override
  Future<AuthUser?> getUser() async {
    return _user;
  }

  @override
  Future<AuthToken?> getToken() async {
    return _token;
  }

  @override
  Future<void> clearAll() async {
    _user = null;
    _token = null;
  }

  @override
  Future<void> clearUser() async {
    _user = null;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }
}

/// Provider that doesn't support refresh
class NoRefreshProvider extends AuthProvider {
  @override
  String get providerId => 'no-refresh';

  @override
  Future<AuthResult> login(Map<String, dynamic> credentials) async {
    final user = DefaultAuthUser(id: 'test-user');
    final token = AuthToken(
      accessToken: 'test-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    return AuthResult(user: user, token: token);
  }

  @override
  Future<AuthToken?> refreshToken(AuthToken currentToken, AuthUser user) async {
    return null; // No refresh support
  }
}

/// Provider that fails during refresh
class FailingRefreshProvider extends AuthProvider {
  @override
  String get providerId => 'failing-refresh';

  @override
  Future<AuthResult> login(Map<String, dynamic> credentials) async {
    final user = DefaultAuthUser(id: 'test-user');
    final token = AuthToken(
      accessToken: 'test-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    return AuthResult(user: user, token: token);
  }

  @override
  Future<AuthToken?> refreshToken(AuthToken currentToken, AuthUser user) async {
    throw AuthException.provider('Refresh failed', providerId);
  }
}
