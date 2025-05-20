import 'dart:async';
import 'dart:io';

/// Types of authentication exceptions that can occur in the authentication flow.
enum AuthExceptionType {
  /// Invalid credentials provided (wrong email/password, etc.)
  invalidCredentials,

  /// Required authentication credentials are missing
  missingCredentials,

  /// User not found during authentication
  userNotFound,

  /// Network error occurred during authentication
  networkError,

  /// Server error occurred during authentication
  serverError,

  /// Session expired or invalid token
  sessionExpired,

  /// User is not authenticated for an operation requiring authentication
  unauthenticated,

  /// Provider specific error (varies based on provider implementation)
  providerError,

  /// Token validation or refresh failed
  tokenError,

  /// User account is disabled, locked, or requires additional verification
  accountIssue,

  /// Permission denied or insufficient privileges
  permissionDenied,

  /// Rate limiting or too many requests
  tooManyRequests,

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

  /// Factory constructor for exceptions caused by user not found.
  factory AuthException.userNotFound([String message = 'User not found']) {
    return AuthException(message: message, type: AuthExceptionType.userNotFound);
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

  /// Factory constructor for session expired exceptions.
  factory AuthException.sessionExpired([String message = 'Your session has expired. Please log in again.']) {
    return AuthException(message: message, type: AuthExceptionType.sessionExpired);
  }

  /// Factory constructor for unauthenticated exceptions.
  factory AuthException.unauthenticated([String message = 'Authentication required for this operation']) {
    return AuthException(message: message, type: AuthExceptionType.unauthenticated);
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

  /// Factory constructor for token-related exceptions.
  factory AuthException.token([String message = 'Token validation or refresh failed']) {
    return AuthException(message: message, type: AuthExceptionType.tokenError);
  }

  /// Factory constructor for account-related exceptions.
  factory AuthException.accountIssue(String issue, [String? message]) {
    return AuthException(
      message: message ?? 'Account issue: $issue',
      type: AuthExceptionType.accountIssue,
      details: {'issue': issue},
    );
  }

  /// Factory constructor for permission-related exceptions.
  factory AuthException.permissionDenied([String message = 'Permission denied']) {
    return AuthException(message: message, type: AuthExceptionType.permissionDenied);
  }

  /// Factory constructor for rate limiting exceptions.
  factory AuthException.tooManyRequests([String message = 'Too many requests. Please try again later.']) {
    return AuthException(message: message, type: AuthExceptionType.tooManyRequests);
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
