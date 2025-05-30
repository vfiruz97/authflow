import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'auth_config.dart';
import 'auth_event_bus.dart';
import 'auth_exception.dart';
import 'auth_provider.dart';
import 'auth_registry.dart';
import 'auth_status.dart';
import 'auth_storage.dart';
import 'auth_token.dart';
import 'auth_user.dart';
import 'events/auth_events.dart';

/// Central manager for authentication state and operations.
class AuthManager {
  /// Singleton instance of the auth manager
  static final AuthManager _instance = AuthManager._();

  // Stream controllers
  final BehaviorSubject<AuthStatus> _statusController = BehaviorSubject<AuthStatus>.seeded(AuthStatus.loading);
  final BehaviorSubject<AuthUser?> _userController = BehaviorSubject<AuthUser?>.seeded(null);
  final BehaviorSubject<AuthToken?> _tokenController = BehaviorSubject<AuthToken?>.seeded(null);
  final BehaviorSubject<String?> _providerIdController = BehaviorSubject<String?>.seeded(null);

  // Event bus for dispatching global events
  final AuthEventBus _eventBus = AuthEventBus();

  // Configuration instance
  AuthConfig? _config;

  // Provider registry
  final AuthRegistry _registry = AuthRegistry();

  static bool _testMode = false;

  /// Enable test mode to create a new instance for each test
  /// Returns true if test mode was enabled
  static bool enableTestMode() {
    _testMode = true;
    return _testMode;
  }

  /// Disable test mode to return to singleton behavior
  /// Returns false if test mode was disabled
  static bool disableTestMode() {
    _testMode = false;
    return _testMode;
  }

  /// Factory constructor that returns the singleton instance or a new instance in test mode
  factory AuthManager() {
    if (_testMode) {
      return AuthManager._();
    }
    return _instance;
  }

  /// Private constructor for singleton
  AuthManager._();

  // Storage instance
  AuthStorage? get _storage => _config?.storage;

  // Default provider ID from configuration
  String? get _defaultProviderId => _config?.defaultProviderId;

  /// Stream of authentication status changes
  Stream<AuthStatus> get statusStream => _statusController.stream.distinct();

  /// Stream of authenticated user changes
  Stream<AuthUser?> get userStream => _userController.stream.distinct();

  /// Stream of authentication token changes
  Stream<AuthToken?> get tokenStream => _tokenController.stream.distinct();

  /// Stream of provider ID changes
  Stream<String?> get providerIdStream => _providerIdController.stream.distinct();

  /// Current authentication status
  AuthStatus get status => _statusController.value;

  /// Currently authenticated user (if any)
  AuthUser? get currentUser => _userController.value;

  /// Current authentication token (if any)
  AuthToken? get currentToken => _tokenController.value;

  /// ID of the current authentication provider (if any)
  String? get currentProviderId => _providerIdController.value;

  /// Whether the user is currently authenticated
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Configures the auth manager with the given configuration
  ///
  /// This must be called before using any authentication functionality.
  Future<void> configure(AuthConfig config) async {
    _config = config;

    // Set initial state to loading
    _statusController.add(AuthStatus.loading);

    try {
      // Try to restore the session
      await _restoreSession();
    } catch (e) {
      // If session restoration fails, set unauthenticated state
      _setUnauthenticated();
    }
  }

  /// Logs in with the default provider and the given credentials
  Future<AuthResult> login(Map<String, dynamic> credentials) async {
    // Try to use the configured default provider first
    String? providerId = _defaultProviderId;

    // If no default provider is configured, try the current provider
    if (providerId == null || !_registry.hasProvider(providerId)) {
      providerId = currentProviderId;
    }

    // If we have a valid provider ID, use it
    if (providerId != null && _registry.hasProvider(providerId)) {
      return loginWithProvider(providerId, credentials);
    }

    // No default or current provider, use the first available one
    if (_registry.providers.isEmpty) {
      throw AuthException.provider(
        'default',
        Exception('No providers registered'),
        'No authentication providers registered',
      );
    }

    return loginWithProvider(_registry.providers.first.providerId, credentials);
  }

  /// Logs in with a specific provider and the given credentials
  Future<AuthResult> loginWithProvider(String providerId, Map<String, dynamic> credentials) async {
    // Set loading state
    _statusController.add(AuthStatus.loading);

    try {
      // Get the provider from the registry
      final provider = _registry.getProvider(providerId);
      if (provider == null) {
        throw AuthException.provider(providerId, Exception('Provider not found'), 'Provider not found: $providerId');
      }

      // Perform the login
      final result = await provider.login(credentials);

      // Update the state
      await _setSession(result.user, result.token, providerId);

      // Return the result
      return result;
    } catch (e) {
      // Set unauthenticated state on error
      _setUnauthenticated();
      rethrow;
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    final user = currentUser;
    final providerId = currentProviderId;

    // Set loading state
    _statusController.add(AuthStatus.loading);

    try {
      // Call the provider's logout method if available
      if (providerId != null) {
        final provider = _registry.getProvider(providerId);
        if (provider != null) {
          try {
            await provider.logout();
          } catch (e) {
            // Ignore provider logout failures, we still want to clear the session
          }
        }
      }

      // Clear the state
      await _clearSession();

      // Dispatch logout event
      _eventBus.dispatch(LogoutEvent(user: user, providerId: providerId));
    } finally {
      // Always set unauthenticated state
      _setUnauthenticated();
    }
  }

  /// Sets the session directly with the given user and token
  ///
  /// This is useful for custom authentication flows or when you already
  /// have a valid user and token.
  Future<void> setSession(AuthUser user, AuthToken token, {String? providerId}) async {
    await _setSession(user, token, providerId);
  }

  /// Refreshes the current authentication token
  ///
  /// Attempts to refresh the current token using the current provider's refresh
  /// functionality. If successful, updates the session with the new token.
  ///
  /// Returns the new token if refresh is successful, null if refresh is not
  /// supported or fails.
  ///
  /// Throws [AuthException] if no session is active or provider is not found.
  Future<AuthToken?> refreshSession() async {
    final currentUser = _userController.value;
    final currentToken = _tokenController.value;
    final currentProviderId = _providerIdController.value;

    // Check if we have an active session
    if (currentUser == null || currentToken == null || currentProviderId == null) {
      throw AuthException.custom(
        'Cannot refresh token: no active session found',
        error: Exception('No active session'),
      );
    }

    // Get the provider
    final provider = _registry.getProvider(currentProviderId);
    if (provider == null) {
      throw AuthException.provider(
        currentProviderId,
        Exception('Provider not found'),
        'Cannot refresh token: provider not found',
      );
    }

    try {
      // Attempt to refresh the token
      final newToken = await provider.refreshToken(currentToken, currentUser);

      if (newToken != null) {
        // Update the session with the new token
        await _setSession(currentUser, newToken, currentProviderId);

        // Dispatch refresh success event
        _eventBus.dispatch(TokenRefreshEvent(
          newToken: newToken,
          oldToken: currentToken,
          user: currentUser,
          providerId: currentProviderId,
          isSuccess: true,
        ));

        return newToken;
      } else {
        // Provider doesn't support refresh or refresh failed
        // Dispatch refresh failed event
        _eventBus.dispatch(TokenRefreshEvent.failed(
          user: currentUser,
          providerId: currentProviderId,
          error: AuthException.custom(
            'Token refresh not supported or failed',
            error: Exception('Refresh failed or not supported'),
          ),
          oldToken: currentToken,
        ));

        return null;
      }
    } catch (e) {
      final error = AuthException.custom('Token refresh failed', error: e);
      // Refresh failed with error
      _eventBus.dispatch(TokenRefreshEvent.failed(
        user: currentUser,
        providerId: currentProviderId,
        error: error,
        oldToken: currentToken,
      ));

      // Rethrow the error for caller to handle
      throw error;
    }
  }

  /// Restores the session from storage
  Future<void> _restoreSession() async {
    if (_storage == null) {
      _setUnauthenticated();
      return;
    }

    // Get token and user from storage
    final token = await _storage!.getToken();
    final user = await _storage!.getUser();

    // If both token and user are available, set the session
    if (token != null && user != null) {
      // Get provider ID from current or default provider, or use the first available
      String? providerId = currentProviderId ?? _defaultProviderId ?? _registry.providers.firstOrNull?.providerId;

      // Check if token is expired and auto-refresh is enabled
      if (token.isExpired && _config?.autoRefreshOnExpiry == true && providerId != null) {
        // Try to refresh the token before clearing the session
        final provider = _registry.getProvider(providerId);
        if (provider != null) {
          try {
            // Temporarily set the session to enable refresh
            _userController.add(user);
            _tokenController.add(token);
            _providerIdController.add(providerId);

            // Attempt to refresh the token
            final newToken = await provider.refreshToken(token, user);
            if (newToken != null) {
              // Refresh successful, update the session
              await _setSession(user, newToken, providerId);

              // Dispatch refresh success event
              _eventBus.dispatch(TokenRefreshEvent(
                newToken: newToken,
                oldToken: token,
                user: user,
                providerId: providerId,
                isSuccess: true,
              ));

              return;
            }
          } catch (e) {
            // Refresh failed, continue with normal expiry handling
            _eventBus.dispatch(TokenRefreshEvent.failed(
              user: user,
              providerId: providerId,
              error: AuthException.custom('Token refresh failed', error: e),
              oldToken: token,
            ));
          }
        }

        // If we reach here, refresh failed or wasn't available
        await _storage!.clearAll();
        _setUnauthenticated();
        return;
      } else if (token.isExpired) {
        // Token expired and auto-refresh is disabled
        await _storage!.clearAll();
        _setUnauthenticated();
        return;
      }

      // If we have a provider, check if the session is valid
      if (providerId != null) {
        final provider = _registry.getProvider(providerId);
        if (provider != null) {
          final isValid = await provider.checkSession(token, user);
          if (!isValid) {
            await _storage!.clearAll();
            _setUnauthenticated();
            return;
          }
        }
      }

      // Set the session without saving to storage (already there)
      _userController.add(user);
      _tokenController.add(token);
      _providerIdController.add(providerId);
      _statusController.add(AuthStatus.authenticated);
    } else {
      _setUnauthenticated();
    }
  }

  /// Sets the session with the given user, token, and provider ID
  Future<void> _setSession(AuthUser user, AuthToken token, String? providerId) async {
    // Update the state
    _userController.add(user);
    _tokenController.add(token);
    _providerIdController.add(providerId);
    _statusController.add(AuthStatus.authenticated);

    // Save to storage if available, but don't fail if storage fails
    if (_storage != null) {
      try {
        await _storage!.saveUser(user);
        await _storage!.saveToken(token);
      } catch (e) {
        // Log storage error but don't fail the authentication
        // The session is still valid in memory
      }
    }

    // Dispatch login event
    _eventBus.dispatch(LoginEvent(user: user, token: token, providerId: providerId ?? 'direct'));
  }

  /// Sets the state to unauthenticated
  void _setUnauthenticated() {
    _statusController.add(AuthStatus.unauthenticated);
    _userController.add(null);
    _tokenController.add(null);
    _providerIdController.add(null);
  }

  /// Clears the current session
  Future<void> _clearSession() async {
    // Clear the state
    _userController.add(null);
    _tokenController.add(null);
    _providerIdController.add(null);

    // Clear storage if available
    if (_storage != null) {
      await _storage!.clearAll();
    }
  }

  /// Resets the AuthManager to its initial state (useful for testing)
  void reset() {
    _setUnauthenticated();
    _registry.clear();
  }

  /// Disposes resources
  void dispose() {
    _registry.clear();
    _eventBus.dispose();
    _statusController.close();
    _userController.close();
    _tokenController.close();
    _providerIdController.close();
  }
}
