import 'package:authflow/authflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthEventBus', () {
    late AuthEventBus eventBus;

    setUpAll(() {
      // Enable test mode for all tests in this group
      AuthEventBus.enableTestMode();
    });

    tearDownAll(() {
      // Disable test mode after all tests
      AuthEventBus.disableTestMode();
    });

    setUp(() {
      // Create a new instance for each test (test mode ensures this is a new instance)
      eventBus = AuthEventBus();
    });

    test('dispatch emits events to listeners', () async {
      // Setup a listener
      final events = <AuthEvent>[];
      final subscription = eventBus.events.listen(events.add);

      // Create and dispatch an event
      final user = DefaultAuthUser(id: 'test-user-id');
      final token = AuthToken(accessToken: 'test-token');
      final loginEvent = LoginEvent(user: user, token: token, providerId: 'test');

      eventBus.dispatch(loginEvent);

      // Give time for the event to be processed
      await Future.delayed(Duration.zero);

      // Verify
      expect(events.length, equals(1));
      expect(events.first, equals(loginEvent));

      // Clean up
      subscription.cancel();
    });

    test('onLogin receives only login events', () async {
      // Setup login event listener
      final loginEvents = <LoginEvent>[];
      final loginSubscription = eventBus.onLogin(loginEvents.add);

      // Create events
      final user = DefaultAuthUser(id: 'test-user-id');
      final token = AuthToken(accessToken: 'test-token');
      final loginEvent = LoginEvent(user: user, token: token, providerId: 'test');
      final logoutEvent = LogoutEvent();

      // Dispatch both events
      eventBus.dispatch(loginEvent);
      eventBus.dispatch(logoutEvent);

      // Give time for events to be processed
      await Future.delayed(Duration.zero);

      // Verify only login events are received
      expect(loginEvents.length, equals(1));
      expect(loginEvents.first, equals(loginEvent));

      // Clean up
      loginSubscription.cancel();
    });

    test('onLogout receives only logout events', () async {
      // Setup logout event listener
      final logoutEvents = <LogoutEvent>[];
      final logoutSubscription = eventBus.onLogout(logoutEvents.add);

      // Create events
      final user = DefaultAuthUser(id: 'test-user-id');
      final token = AuthToken(accessToken: 'test-token');
      final loginEvent = LoginEvent(user: user, token: token, providerId: 'test');
      final logoutEvent = LogoutEvent();

      // Dispatch both events
      eventBus.dispatch(loginEvent);
      eventBus.dispatch(logoutEvent);

      // Give time for events to be processed
      await Future.delayed(Duration.zero);

      // Verify only logout events are received
      expect(logoutEvents.length, equals(1));
      expect(logoutEvents.first, equals(logoutEvent));

      // Clean up
      logoutSubscription.cancel();
    });
  });
}
