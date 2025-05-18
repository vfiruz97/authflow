import 'package:flutter/material.dart';

import '../auth_manager.dart';
import '../auth_status.dart';
import '../auth_token.dart';
import '../auth_user.dart';

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

  /// Creates a new [AuthBuilder] widget
  const AuthBuilder({
    super.key,
    required this.authenticated,
    required this.unauthenticated,
    this.loading,
    this.authManager,
  });

  @override
  Widget build(BuildContext context) {
    final manager = authManager ?? AuthManager();

    return StreamBuilder<AuthStatus>(
      stream: manager.statusStream,
      builder: (context, statusSnapshot) {
        // Show loading widget if status is loading or stream hasn't emitted yet
        if (statusSnapshot.connectionState == ConnectionState.waiting || statusSnapshot.data == AuthStatus.loading) {
          return loading?.call(context) ?? const Center(child: CircularProgressIndicator());
        }

        // If not authenticated, show unauthenticated widget
        if (statusSnapshot.data != AuthStatus.authenticated) {
          return unauthenticated(context);
        }

        // If authenticated, get user and token and build authenticated view
        return StreamBuilder<AuthUser?>(
          stream: manager.userStream,
          builder: (context, userSnapshot) {
            return StreamBuilder<AuthToken?>(
              stream: manager.tokenStream,
              builder: (context, tokenSnapshot) {
                // If user or token is not available, show unauthenticated view
                if (!userSnapshot.hasData ||
                    userSnapshot.data == null ||
                    !tokenSnapshot.hasData ||
                    tokenSnapshot.data == null) {
                  return unauthenticated(context);
                }

                // Build authenticated view with user and token
                return authenticated(context, userSnapshot.data!, tokenSnapshot.data!);
              },
            );
          },
        );
      },
    );
  }
}
