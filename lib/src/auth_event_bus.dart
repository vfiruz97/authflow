import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'events/auth_events.dart';

/// Simple event bus for auth events that allows components to subscribe to auth events.
class AuthEventBus {
  /// Singleton instance
  static final AuthEventBus _instance = AuthEventBus._internal();

  /// Flag to enable test mode (non-singleton behavior)
  static bool _testMode = false;

  /// BehaviorSubject for auth events with replay of the latest event
  final BehaviorSubject<AuthEvent> _eventSubject = BehaviorSubject<AuthEvent>();

  /// Stream of auth events that also emits the most recent event to new subscribers
  Stream<AuthEvent> get events => _eventSubject.stream;

  /// The most recent event that was dispatched (if any)
  AuthEvent? get lastEvent => _eventSubject.hasValue ? _eventSubject.value : null;

  /// Factory constructor that returns either the singleton instance or a new instance in test mode
  factory AuthEventBus() {
    if (_testMode) {
      return AuthEventBus._internal();
    }
    return _instance;
  }

  /// Private constructor for singleton
  AuthEventBus._internal();

  /// Enable test mode to create a new instance for each test
  /// Returns true if test mode was enabled
  static bool enableTestMode() {
    _testMode = true;
    return _testMode;
  }

  /// Disable test mode to return to singleton behavior
  /// Returns false if test mode was disabled
  static bool disableTestMode() {
    _testMode = false;
    return _testMode;
  }

  /// Clears all events (useful for testing)
  void clear() {
    // The proper way to clear a BehaviorSubject without closing it
    if (_eventSubject.hasValue && !_eventSubject.isClosed) {
      // Add a dummy event and then discard it to clear the behavior subject
      // without closing it, which would make it unusable
      _eventSubject.drain();
    }
  }

  /// Dispatches an auth event to all listeners
  void dispatch(AuthEvent event) {
    _eventSubject.add(event);
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
    _eventSubject.close();
  }
}
