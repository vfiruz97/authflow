import 'auth_token.dart';
import 'auth_user.dart';

/// Result of a login operation containing both user and token
class AuthResult {
  /// The authenticated user
  final AuthUser user;

  /// The authentication token
  final AuthToken token;

  /// Creates a new [AuthResult] with the given user and token
  const AuthResult({required this.user, required this.token});
}

/// Abstract interface for authentication providers.
/// Extend this class to implement custom authentication strategies.
abstract class AuthProvider {
  /// Unique identifier for this provider
  String get providerId;

  /// Performs the login operation with provider-specific credentials
  ///
  /// Returns an [AuthResult] containing both the user and token on success.
  /// Implementations should handle errors and rethrow them with clear messages.
  Future<AuthResult> login(Map<String, dynamic> credentials);

  /// Performs the logout operation for this provider
  ///
  /// This method is called when the user explicitly logs out.
  ///
  /// **Note:** Overriding this is optional. If not overridden, or if your provider does not require cleanup,
  /// AuthManager will always clear the session and storage regardless.
  /// Override only if your provider needs to perform remote or provider-specific cleanup.
  Future<void> logout() async {
    // Perform any necessary cleanup for the provider
  }

  /// Checks if the current session is valid
  ///
  /// This is useful for providers that need to validate tokens
  /// or check session status on app startup.
  ///
  /// Returns true if the session is valid, false otherwise.
  Future<bool> checkSession(AuthToken token, AuthUser user) async {
    return !token.isExpired;
  }

  /// Refreshes the authentication token using a refresh token
  ///
  /// This method should be implemented by providers that support token refresh.
  /// If the provider doesn't support refresh tokens, it can return null.
  ///
  /// [currentToken] - The current (possibly expired) token
  /// [user] - The current authenticated user
  ///
  /// Returns a new [AuthToken] with refreshed access token, or null if refresh
  /// is not supported or fails.
  Future<AuthToken?> refreshToken(AuthToken currentToken, AuthUser user) async {
    // Default implementation: refresh not supported
    return null;
  }

  /// Creates a provider-specific error message for failed logins
  ///
  /// This method can be overridden to provide more specific error messages
  /// based on the provider's authentication flow.
  String formatLoginError(dynamic error) {
    return 'Authentication failed: ${error.toString()}';
  }
}
