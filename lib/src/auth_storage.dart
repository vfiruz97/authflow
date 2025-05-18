import 'auth_token.dart';
import 'auth_user.dart';

/// Abstract interface for storing and retrieving authentication state.
abstract class AuthStorage {
  /// Saves the given [AuthToken] to storage
  Future<void> saveToken(AuthToken token);

  /// Retrieves the stored [AuthToken] if available
  Future<AuthToken?> getToken();

  /// Clears the stored token
  Future<void> clearToken();

  /// Saves the given [AuthUser] to storage
  Future<void> saveUser(AuthUser user);

  /// Retrieves the stored [AuthUser] if available
  ///
  /// Must be implemented by concrete storage implementations to handle
  /// the deserialization of the specific [AuthUser] implementation.
  Future<AuthUser?> getUser();

  /// Clears the stored user
  Future<void> clearUser();

  /// Clears both token and user from storage
  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
  }
}
