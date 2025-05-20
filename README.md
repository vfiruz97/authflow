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

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  authflow: ^0.0.1
```

Then run:

```bash
flutter pub get
```

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
  defaultProviderId: 'email_password',
  storage: SecureAuthStorage.withDefaultUser(),
));
```

---

## 🚀 Usage

### Login

```dart
// Login with default provider
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
)
```

## 🔧 Custom Providers

Implement your own authentication providers by extending `AuthProvider`:

```dart
class MyCustomAuthProvider extends AuthProvider {
  @override
  String get providerId => 'custom_provider';

  @override
  Future<AuthResult> login(Map<String, dynamic> credentials) async {
    // Implement your authentication logic here

    // Create user and token
    final user = DefaultAuthUser(
      id: 'user123',
      email: 'user@example.com',
    );

    final token = AuthToken(
      accessToken: 'my-access-token',
      refreshToken: 'my-refresh-token',
      expiresAt: DateTime.now().add(Duration(hours: 1)),
    );

    return AuthResult(user: user, token: token);
  }

  @override
  Future<void> logout() async {
    // Implement any custom logout logic here
  }
}
```

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

  // Access original error (if any)
  if (e.error != null) {
    print('Original error: ${e.error}');
  }

  // Handle specific error types
  switch (e.type) {
    case AuthExceptionType.missingCredentials:
      showMissingFieldsError(e.message);
      break;
    case AuthExceptionType.invalidCredentials:
      showInvalidCredentialsError();
      break;
    case AuthExceptionType.networkError:
      showNetworkError();
      break;
    // Handle other error types...
    default:
      showGenericError(e.message);
  }
}
```

### Available Exception Types

The `AuthExceptionType` enum provides the following error categories:

- `invalidCredentials`: Wrong password, email not found, etc.
- `missingCredentials`: Required fields (email, password) missing
- `userNotFound`: User doesn't exist
- `networkError`: Network connectivity issues
- `serverError`: Server-side errors
- `sessionExpired`: Token expired or invalid
- `unauthenticated`: Authentication required
- `providerError`: Provider-specific errors
- `tokenError`: Token validation/refresh failures
- `accountIssue`: Account disabled, locked, etc.
- `permissionDenied`: Insufficient privileges
- `tooManyRequests`: Rate limiting
- `unknown`: Unclassified errors

### Creating Custom Exceptions

You can create custom auth exceptions:

```dart
// Using a factory constructor
final exception = AuthException.invalidCredentials('Custom error message');

// Or the generic constructor
final exception = AuthException(
  message: 'Custom error message',
  type: AuthExceptionType.networkError,
  error: originalError,
  details: {'retry': true, 'timeout': 30},
);
```

---

## 🧱 Extending

### Custom Provider

Implement `AuthProvider`, return an `AuthResult`, and register via `AuthRegistry`:

```dart
class MyProvider extends AuthProvider {
  @override
  Future<AuthResult?> login({Map<String, dynamic>? credentials}) async {
    // your logic
  }

  // ...logout(), isAuthenticated(), currentUser()
}

AuthRegistry.register('my_provider', MyProvider());
```

### Custom User or Storage

- Implement your own `AuthUser` to match your API
- Implement `AuthStorage` for custom persistence

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Firuz Vorisov**  
[github.com/vfiruz97](https://github.com/vfiruz97)

Feel free to open issues or contribute via PR!
