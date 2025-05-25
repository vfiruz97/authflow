import 'dart:async';
import 'dart:io';

/// Types of authentication exceptions that can occur in the authentication flow.
enum AuthExceptionType {
  /// Invalid credentials provided (wrong email/password, etc.)
  invalidCredentials,

  /// Required authentication credentials are missing
  missingCredentials,

  /// Provider specific error (varies based on provider implementation)
  providerError,

  /// Network-related error (connectivity issues, timeouts, etc.)
  networkError,

  /// Server-related error (backend issues, API errors, etc.)
  serverError,

  /// Custom error type for user-defined authentication errors
  custom,

  /// Unknown or unclassified error
  unknown,
}

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

  /// Factory constructor for exceptions caused by invalid credentials.
  factory AuthException.invalidCredentials([String message = 'Invalid credentials provided']) {
    return AuthException(message: message, type: AuthExceptionType.invalidCredentials);
  }

  /// Factory constructor for exceptions caused by missing credentials.
  factory AuthException.missingCredentials([String message = 'Required credentials are missing']) {
    return AuthException(message: message, type: AuthExceptionType.missingCredentials);
  }

  /// Factory constructor for network-related exceptions.
  factory AuthException.network(Object error, [String? message]) {
    return AuthException(
      message: message ?? 'A network error occurred: ${error.toString()}',
      error: error,
      type: AuthExceptionType.networkError,
    );
  }

  /// Factory constructor for server-related exceptions.
  factory AuthException.server(Object error, [String? message]) {
    return AuthException(
      message: message ?? 'A server error occurred: ${error.toString()}',
      error: error,
      type: AuthExceptionType.serverError,
    );
  }

  /// Factory constructor for provider-specific exceptions.
  factory AuthException.provider(String providerId, Object error, [String? message]) {
    return AuthException(
      message: message ?? 'Provider error ($providerId): ${error.toString()}',
      error: error,
      type: AuthExceptionType.providerError,
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

  /// Factory constructor for converting various exceptions to [AuthException].
  factory AuthException.from(Object error) {
    if (error is AuthException) {
      return error;
    }

    // Handle common exception types
    if (error is FormatException) {
      return AuthException(
        message: 'Format error: ${error.message}',
        error: error,
        type: AuthExceptionType.missingCredentials,
      );
    } else if (error is SocketException || error is HttpException) {
      return AuthException.network(error);
    } else if (error is TimeoutException) {
      return AuthException(
        message: 'Operation timed out: ${error.message ?? ''}',
        error: error,
        type: AuthExceptionType.networkError,
      );
    }

    // Default to unknown error
    return AuthException.unknown(error);
  }

  @override
  String toString() => 'AuthException($type): $message';
}
