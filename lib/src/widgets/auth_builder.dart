import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../auth_manager.dart';
import '../auth_status.dart';
import '../auth_token.dart';
import '../auth_user.dart';

/// Record that holds the combined authentication state
typedef AuthStateRecord = ({AuthStatus status, AuthUser? user, AuthToken? token});

/// A builder widget that reacts to authentication state changes.
class AuthBuilder extends StatelessWidget {
  /// Widget to display when the user is authenticated
  final Widget Function(BuildContext context, AuthUser user, AuthToken token) authenticated;

  /// Widget to display when the user is not authenticated
  final Widget Function(BuildContext context) unauthenticated;

  /// Widget to display while the authentication state is being determined
  final Widget Function(BuildContext context)? loading;

  /// The [AuthManager] instance to use
  final AuthManager? authManager;

  /// Optional function that determines when the builder should rebuild
  final bool Function(AuthStateRecord previous, AuthStateRecord current)? buildWhen;

  /// Creates a new [AuthBuilder] widget
  const AuthBuilder({
    super.key,
    required this.authenticated,
    required this.unauthenticated,
    this.loading,
    this.authManager,
    this.buildWhen,
  });

  /// Creates a combined stream of authentication state
  Stream<AuthStateRecord> _createCombinedStream(AuthManager manager) {
    final baseStream = Rx.combineLatest3<AuthStatus, AuthUser?, AuthToken?, AuthStateRecord>(
      manager.statusStream,
      manager.userStream,
      manager.tokenStream,
      (status, user, token) => (status: status, user: user, token: token),
    ).distinct();
    // Apply custom buildWhen logic if provided
    if (buildWhen != null) {
      return baseStream.distinct((p, n) => !buildWhen!(p, n));
    }
    return baseStream;
  }

  @override
  Widget build(BuildContext context) {
    final manager = authManager ?? AuthManager();

    return StreamBuilder<AuthStateRecord>(
      stream: _createCombinedStream(manager),
      builder: (context, snapshot) {
        // Show loading widget if connection is waiting or status is loading
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data?.status == AuthStatus.loading) {
          return loading?.call(context) ?? const Center(child: CircularProgressIndicator());
        }

        final authState = snapshot.data!;

        // If not authenticated or missing user/token, show unauthenticated widget
        if (authState.status != AuthStatus.authenticated || authState.user == null || authState.token == null) {
          return unauthenticated(context);
        }

        // If token is expired, show unauthenticated widget
        if (authState.token!.isExpired) {
          return unauthenticated(context);
        }

        // Build authenticated view with user and token
        return authenticated(context, authState.user!, authState.token!);
      },
    );
  }
}
