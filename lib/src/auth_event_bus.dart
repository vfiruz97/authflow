import 'dart:async';

import 'events/auth_events.dart';

/// Simple event bus for auth events that allows components to subscribe to auth events.
class AuthEventBus {
  /// Singleton instance
  static final AuthEventBus _instance = AuthEventBus._();

  /// Stream controller for auth events
  final StreamController<AuthEvent> _eventController = StreamController<AuthEvent>.broadcast();

  /// Stream of auth events
  Stream<AuthEvent> get events => _eventController.stream;

  /// Factory constructor that returns the singleton instance
  factory AuthEventBus() => _instance;

  /// Private constructor for singleton
  AuthEventBus._();

  /// Dispatches an auth event to all listeners
  void dispatch(AuthEvent event) {
    _eventController.add(event);
  }

  /// Listens to auth events of a specific type
  StreamSubscription<T> on<T extends AuthEvent>(void Function(T event) callback) {
    return events.where((event) => event is T).cast<T>().listen(callback);
  }

  /// Listens to login events
  StreamSubscription<LoginEvent> onLogin(void Function(LoginEvent event) callback) {
    return on<LoginEvent>(callback);
  }

  /// Listens to logout events
  StreamSubscription<LogoutEvent> onLogout(void Function(LogoutEvent event) callback) {
    return on<LogoutEvent>(callback);
  }

  /// Disposes the event bus
  void dispose() {
    _eventController.close();
  }
}
