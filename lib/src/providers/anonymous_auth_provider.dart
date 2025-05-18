import 'dart:math';

import '../auth_provider.dart';
import '../auth_token.dart';
import '../auth_user.dart';

/// Authentication provider that creates anonymous user sessions.
class AnonymousAuthProvider extends AuthProvider {
  @override
  String get providerId => 'anonymous';

  /// Optional function to generate a unique ID for anonymous users
  final String Function()? _idGenerator;

  /// Creates a new [AnonymousAuthProvider] instance
  ///
  /// An optional [idGenerator] can be provided to customize how anonymous
  /// user IDs are generated. If not provided, a random UUID-like string
  /// will be generated.
  AnonymousAuthProvider({String Function()? idGenerator}) : _idGenerator = idGenerator;

  @override
  Future<AuthResult> login(Map<String, dynamic> credentials) async {
    // Generate a random ID if no ID generator is provided
    final id = _idGenerator?.call() ?? _generateRandomId();

    // Create an anonymous user
    final user = DefaultAuthUser(id: id, isAnonymous: true);

    // Create a token for the anonymous session
    final token = AuthToken(
      accessToken: 'anonymous-${user.id}',
      // Set an expiration date for the anonymous session (e.g., 7 days)
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    return AuthResult(user: user, token: token);
  }

  @override
  Future<void> logout() async {
    // No special logout handling needed for anonymous users
  }

  /// Generates a random ID for anonymous users
  String _generateRandomId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(24, (index) => chars[random.nextInt(chars.length)]).join() +
        DateTime.now().millisecondsSinceEpoch.toString();
  }
}
