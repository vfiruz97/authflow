# Authflow

**Authflow** is a Flutter-first authentication toolkit that provides flexible, stream-based authentication with multiple providers, token handling, and composable UI widgets.

## 🔥 Features

- ✅ Modular provider-based authentication
- 🔐 Token + user result on login
- 📦 Pluggable secure/local storage system
- 🔄 Reactive streams for auth status, user, and token
- 📡 Global login/logout event support
- 🧱 Customizable user model and providers
- 🧩 UI widgets for seamless auth-based rendering
- 🛡️ Standardized exception handling

---

## 🛠️ Configuration

Set up your providers and storage with `AuthConfig`, then initialize the system:

```dart
// Create providers
final anonymousProvider = AnonymousAuthProvider();
final emailProvider = MockEmailPasswordAuthProvider();

// Configure auth manager
await AuthManager().configure(AuthConfig(
  providers: [anonymousProvider, emailProvider],
  defaultProviderId: 'email_password', // Set the default provider
  storage: SecureAuthStorage.withDefaultUser(),
));
```

> **Note:** Setting `defaultProviderId` is important when using `AuthManager().login()`.
> Without it, the system will try to use the current provider (if authenticated) or
> fall back to the first registered provider.

---

## 🚀 Usage

### Login

```dart
// Login with default provider (as configured in AuthConfig)
final result = await AuthManager().login({
  'email': 'user@example.com',
  'password': 'secret',
});

// Login with specific provider
final result = await AuthManager().loginWithProvider(
  'anonymous',
  {},
);

// Access user and token from result
final user = result.user;
final token = result.token;
```

### Manual Session

```dart
// Inject a session directly
await AuthManager().setSession(
  user,
  token,
  providerId: 'custom',
);
```

### Logout

```dart
await AuthManager().logout();
```

### Auth State

```dart
// Get current state
final isLoggedIn = AuthManager().isAuthenticated;
final user = AuthManager().currentUser;
final token = AuthManager().currentToken;

// Listen to auth state changes
AuthManager().statusStream.listen((status) {
  print("Auth status: $status");
});

// Listen to user changes
AuthManager().userStream.listen((user) {
  if (user != null) {
    print("User: ${user.id}");
  }
});

// Listen to token changes
AuthManager().tokenStream.listen((token) {
  if (token != null) {
    print("Token: ${token.accessToken}");
  }
});
```

### Global Events

```dart
// Listen to all login events
AuthEventBus().onLogin((event) {
  print('User logged in: ${event.user.id} via ${event.providerId}');
});

// Listen to all logout events
AuthEventBus().onLogout((event) {
  print('User logged out: ${event.user?.id}');
});
```

---

## 🧩 Flutter UI Integration

Use `AuthBuilder` to rebuild UI based on authentication state:

```dart
AuthBuilder(
  authenticated: (context, user, token) {
    return HomeScreen(user: user);
  },
  unauthenticated: (context) {
    return LoginScreen();
  },
  loading: (context) {
    return LoadingScreen();
  },
  // Optional: Control when rebuilds happen
  buildWhen: (previous, current) {
    // Don't rebuild during login attempts
    if (current.status == AuthStatus.loading &&
        previous.status != AuthStatus.loading) {
      return false;
    }
    return true;
  },
);
```

> **Tip:** The `buildWhen` parameter helps prevent UI flashing during authentication state changes. For example, you can use it to prevent the login screen from disappearing momentarily during login attempts.

---

## 🧱 Extending

### Custom Provider

Implement `AuthProvider`, return an `AuthResult`, and add it to your `AuthConfig`:

```dart
class MyProvider extends AuthProvider {
  @override
  String get providerId => 'my_provider';

  @override
  Future<AuthResult> login(Map<String, dynamic> credentials) async {
    // Implement your authentication logic here
    // ...

    // Return AuthResult with user and token
    return AuthResult(user: customUser, token: customToken);
  }

  // ...logout(), isAuthenticated(), currentUser()
}

// Configure AuthManager with your custom provider
await AuthManager().configure(AuthConfig(
  providers: [
    MyProvider(),
    AnonymousAuthProvider(),
  ],
  // Optionally set your custom provider as default
  defaultProviderId: 'my_provider',
  storage: SecureAuthStorage.withDefaultUser(),
));
```

### Custom User or Storage

- Implement your own `AuthUser` to match your API
- Implement `AuthStorage` for custom persistence

## 🔐 Custom User Model

Extend `AuthUser` to create your own user model:

```dart
class MyUser extends AuthUser {
  @override
  final String id;

  @override
  final String? email;

  @override
  final String? displayName;

  final String? photoUrl;
  final List<String> roles;

  MyUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.roles = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'roles': roles,
    };
  }

  factory MyUser.fromJson(Map<String, dynamic> json) {
    return MyUser(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  factory MyUser.deserialize(String data) {
    return MyUser.fromJson(jsonDecode(data));
  }
}

// Use with custom storage:
final storage = SecureAuthStorage(
  userDeserializer: (data) => MyUser.deserialize(data),
);
```

---

## 🛡️ Error Handling

Authflow provides a standardized exception handling system with `AuthException`:

```dart
try {
  final result = await AuthManager().login({
    'email': 'user@example.com',
    // missing password
  });
} on AuthException catch (e) {
  // Access type and message
  print('Error type: ${e.type}');
  print('Error message: ${e.message}');

  // Handle specific error types
  switch (e.type) {
    case AuthExceptionType.credentials:
      showCredentialsError(e.message);
      break;
    case AuthExceptionType.provider:
      showProviderError(e.message);
      break;
    // Handle other error types...
    default:
      showGenericError(e.message);
  }
}
```

### Available Exception Types

The `AuthExceptionType` enum provides these core error categories:

- `credentials`: Issues with credentials (missing, invalid, etc.)
- `provider`: Provider-specific errors (provider not found, implementation errors)
- `custom`: For user-defined authentication errors
- `unknown`: Unclassified errors

### Creating Custom Exceptions

```dart
// Using a factory constructor
final exception = AuthException.credentials('Password is too weak');

// For provider-specific errors
final providerException = AuthException.provider(
  'google_signin',
  originalError,
  'Failed to authenticate with Google'
);

// For your own custom authentication errors
final myException = AuthException.custom(
  'Account requires verification',
  error: originalError,
  details: {'verificationType': 'email'},
);
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Firuz Vorisov**  
[github.com/vfiruz97](https://github.com/vfiruz97)

Feel free to open issues or contribute via PR!
