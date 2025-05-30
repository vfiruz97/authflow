import '../auth_exception.dart';
import '../auth_token.dart';
import '../auth_user.dart';

/// Base class for authentication events
abstract class AuthEvent {
  /// Type of the auth event
  final String type;

  /// Creates a new [AuthEvent] with the given type
  const AuthEvent(this.type);
}

/// Event dispatched when a user logs in
class LoginEvent extends AuthEvent {
  /// The authenticated user
  final AuthUser user;

  /// The authentication token
  final AuthToken token;

  /// Provider ID used for login
  final String providerId;

  /// Creates a new [LoginEvent] with the given user and token
  const LoginEvent({required this.user, required this.token, required this.providerId}) : super('login');
}

/// Event dispatched when a user logs out
class LogoutEvent extends AuthEvent {
  /// The user who was logged out (if available)
  final AuthUser? user;

  /// Provider ID used for the logged out session
  final String? providerId;

  /// Creates a new [LogoutEvent]
  const LogoutEvent({this.user, this.providerId}) : super('logout');
}

/// Event dispatched when a token is refreshed
class TokenRefreshEvent extends AuthEvent {
  /// The refreshed authentication token
  final AuthToken newToken;

  /// The previous (expired) token
  final AuthToken? oldToken;

  /// The user for whom the token was refreshed
  final AuthUser user;

  /// Provider ID that performed the refresh
  final String providerId;

  /// Whether the refresh was successful
  final bool isSuccess;

  /// Error that occurred during refresh (if any)
  final AuthException? error;

  /// Creates a new [TokenRefreshEvent]
  const TokenRefreshEvent({
    required this.newToken,
    this.oldToken,
    required this.user,
    required this.providerId,
    this.isSuccess = true,
    this.error,
  }) : super('token_refresh');

  /// Creates a failed token refresh event
  const TokenRefreshEvent.failed({
    required this.user,
    required this.providerId,
    required this.error,
    this.oldToken,
  })  : newToken = const AuthToken(accessToken: '', expiresAt: null),
        isSuccess = false,
        super('token_refresh');
}
