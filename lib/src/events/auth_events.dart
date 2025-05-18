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
