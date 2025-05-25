/// Types of authentication exceptions that can occur in the authentication flow.
enum AuthExceptionType { credentials, provider, custom, unknown }

/// Standardized exception class for authentication errors in the AuthFlow package.
class AuthException implements Exception {
  /// Human-readable error message
  final String message;

  /// Original error that caused this exception (if available)
  final Object? error;

  /// Type of authentication exception
  final AuthExceptionType type;

  /// Additional error details or context (optional)
  final Map<String, dynamic>? details;

  /// Creates a new [AuthException] with the given message and type.
  const AuthException({required this.message, required this.type, this.error, this.details});

  /// Factory constructor for exceptions caused by credential-related issues.
  factory AuthException.credentials([String message = 'Invalid or missing credentials']) {
    return AuthException(message: message, type: AuthExceptionType.credentials);
  }

  /// Factory constructor for provider-specific exceptions.
  factory AuthException.provider(String providerId, Object error, [String? message]) {
    return AuthException(
      message: message ?? 'Provider error ($providerId): ${error.toString()}',
      error: error,
      type: AuthExceptionType.provider,
      details: {'providerId': providerId},
    );
  }

  /// Factory constructor for custom exceptions defined by the user.
  factory AuthException.custom(String message, {Object? error, Map<String, dynamic>? details}) {
    return AuthException(message: message, type: AuthExceptionType.custom, error: error, details: details);
  }

  /// Factory constructor for unknown exceptions.
  factory AuthException.unknown(Object? error, [String? message]) {
    return AuthException(
      message: message ?? 'An unknown error occurred: ${error?.toString() ?? 'No details available'}',
      error: error,
      type: AuthExceptionType.unknown,
    );
  }

  /// Convert any exception to an AuthException
  static AuthException from(Object error) {
    if (error is AuthException) {
      return error;
    }

    // Default to unknown error
    return AuthException.unknown(error);
  }

  @override
  String toString() => 'AuthException($type): $message';
}
