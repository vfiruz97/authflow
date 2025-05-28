import 'package:shared_preferences/shared_preferences.dart';

import '../auth_storage.dart';
import '../auth_token.dart';
import '../auth_user.dart';

/// Default implementation of [AuthStorage] using SharedPreferences for persistence.
class SecureAuthStorage implements AuthStorage {
  /// Key for storing the auth token
  static const String _tokenKey = 'authflow_token';

  /// Key for storing the auth user
  static const String _userKey = 'authflow_user';

  /// Creates a serializer function for the user model
  final AuthUser Function(String serialized) _userDeserializer;

  /// Creates a new [SecureAuthStorage] instance
  ///
  /// The [userDeserializer] is responsible for converting the serialized user
  /// data back into an [AuthUser] instance. This is necessary because [AuthUser]
  /// is an abstract class and the storage needs to know the concrete implementation.
  ///
  /// Example:
  /// ```dart
  /// final storage = SecureAuthStorage(
  ///   userDeserializer: (data) => MyUser.deserialize(data),
  /// );
  /// ```
  SecureAuthStorage({required AuthUser Function(String serialized) userDeserializer})
      : _userDeserializer = userDeserializer;

  /// Factory constructor for using the default user implementation
  factory SecureAuthStorage.withDefaultUser() {
    return SecureAuthStorage(userDeserializer: (data) => DefaultAuthUser.deserialize(data));
  }

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  @override
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  @override
  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
  }

  @override
  Future<AuthToken?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenData = prefs.getString(_tokenKey);
    if (tokenData == null) return null;

    try {
      return AuthToken.deserialize(tokenData);
    } catch (e) {
      // If deserialization fails, clear the token and return null
      await clearToken();
      return null;
    }
  }

  @override
  Future<AuthUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) return null;

    try {
      return _userDeserializer(userData);
    } catch (e) {
      // If deserialization fails, clear the user and return null
      await clearUser();
      return null;
    }
  }

  @override
  Future<void> saveToken(AuthToken token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.serialize());
  }

  @override
  Future<void> saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.serialize());
  }
}
