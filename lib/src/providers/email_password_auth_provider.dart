import '../auth_provider.dart';
import '../auth_token.dart';
import '../auth_user.dart';

/// Credentials for email/password authentication
class EmailPasswordCredentials {
  /// Email address for login
  final String email;

  /// Password for login
  final String password;

  /// Creates new [EmailPasswordCredentials] with the given email and password
  const EmailPasswordCredentials({required this.email, required this.password});
}

/// Authentication provider for email/password login.
///
/// This is an abstract class that must be extended with a concrete implementation
/// that connects to a specific backend authentication service.
abstract class EmailPasswordAuthProvider extends AuthProvider {
  @override
  String get providerId => 'email_password';

  @override
  Future<AuthResult> login(Map<String, dynamic> credentials) async {
    // Extract and validate email and password from credentials
    final email = credentials['email'] as String?;
    final password = credentials['password'] as String?;

    if (email == null || email.isEmpty) {
      throw FormatException('Email is required');
    }

    if (password == null || password.isEmpty) {
      throw FormatException('Password is required');
    }

    // Call the implementation-specific authenticate method
    return authenticate(EmailPasswordCredentials(email: email, password: password));
  }

  /// Authenticates a user with the given credentials
  ///
  /// Implementations should connect to their specific backend authentication
  /// service and return an [AuthResult] containing both the user and token.
  Future<AuthResult> authenticate(EmailPasswordCredentials credentials);

  @override
  String formatLoginError(dynamic error) {
    if (error is FormatException) {
      return error.message;
    }

    return 'Email/password authentication failed: ${error.toString()}';
  }
}

/// Mock implementation of [EmailPasswordAuthProvider] for testing or demos.
///
/// This provider allows any email/password combination and creates mock users.
class MockEmailPasswordAuthProvider extends EmailPasswordAuthProvider {
  @override
  Future<AuthResult> authenticate(EmailPasswordCredentials credentials) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Create a mock user from the credentials
    final user = DefaultAuthUser(
      id: 'user-${credentials.email.hashCode}',
      email: credentials.email,
      displayName: credentials.email.split('@').first,
    );

    // Create a mock token
    final token = AuthToken(
      accessToken: 'mock-token-${user.id}',
      refreshToken: 'mock-refresh-${user.id}',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    return AuthResult(user: user, token: token);
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }
}
