import 'dart:math';

import '../auth_exception.dart';
import '../auth_provider.dart';
import '../auth_token.dart';
import '../auth_user.dart';

/// Authentication provider that creates anonymous user sessions.
class AnonymousAuthProvider extends AuthProvider {
  @override
  String get providerId => 'anonymous';

  /// Optional function to generate a unique ID for anonymous users
  final String Function()? _idGenerator;

  /// Optional expiration duration for anonymous sessions
  /// Defaults to 7 days if not provided
  final Duration expirationDuration;

  /// Creates a new [AnonymousAuthProvider] instance
  ///
  /// An optional [idGenerator] can be provided to customize how anonymous
  /// user IDs are generated. If not provided, a random UUID-like string
  /// will be generated.
  /// An optional [expirationDuration] can be provided to set the
  /// expiration duration for anonymous sessions. Defaults to 7 days.
  AnonymousAuthProvider({String Function()? idGenerator, Duration? expirationDuration})
    : _idGenerator = idGenerator,
      expirationDuration = expirationDuration ?? const Duration(days: 7);

  @override
  Future<AuthResult> login(Map<String, dynamic> credentials) async {
    try {
      // Generate a random ID if no ID generator is provided
      final id = _idGenerator?.call() ?? _generateRandomId();

      // Create an anonymous user
      final user = DefaultAuthUser(id: id, isAnonymous: true);

      // Create a token for the anonymous session
      final token = AuthToken(
        accessToken: 'anonymous-${user.id}',
        // Set an expiration date for the anonymous session (e.g., 7 days)
        expiresAt: DateTime.now().add(expirationDuration),
      );

      return AuthResult(user: user, token: token);
    } catch (e) {
      throw AuthException.from(e);
    }
  }

  @override
  Future<void> logout() async {
    // No special logout handling needed for anonymous users
  }

  /// Generates a random ID for anonymous users
  String _generateRandomId() {
    try {
      final random = Random();
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      return List.generate(24, (index) => chars[random.nextInt(chars.length)]).join() +
          DateTime.now().millisecondsSinceEpoch.toString();
    } catch (e) {
      throw AuthException.unknown(e, 'Failed to generate random ID for anonymous user');
    }
  }
}
