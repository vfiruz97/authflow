# Authflow

**Authflow** is a modular authentication orchestration package for Flutter. It helps you manage authentication flows, state, and persistence, while letting you plug in your own authentication logic, user model, and storage. Authflow is not a plug-and-play backend solution: you bring your own `AuthProvider` for your backend, and Authflow manages the rest.

---

## What Does Authflow Do?

| Authflow Manages                | You Must Implement                  |
| ------------------------------- | ----------------------------------- |
| Provider orchestration          | Your own `AuthProvider`             |
| Session state & persistence     | (Optionally) your own `AuthUser`    |
| Reactive streams for status     | (Optionally) your own `AuthStorage` |
| Global login/logout events      | UI and error handling               |
| UI helpers (e.g. `AuthBuilder`) |                                     |

> **Note:** Authflow does not provide production-ready providers for every backend. You are expected to implement your own provider(s) for your authentication system.
>
> **How provider selection works:** When you call `AuthManager().login()`, Authflow uses the provider with the `defaultProviderId` you configured. If you did not set a `defaultProviderId`, it will use the first provider in your list. Make sure to set this explicitly if you have multiple providers.

---

## 🚀 Quickstart

1. **Implement your own `AuthProvider`** (see below for details)
2. (Optionally) **Customize your user model** by extending `AuthUser`
3. (Optionally) **Customize storage** by implementing `AuthStorage`
4. **Configure** `AuthManager` with your providers and storage
5. **Use** `AuthBuilder` or streams to react to auth state in your UI

---

## 🔌 Built-in AuthProviders

- `AnonymousAuthProvider` – for anonymous login (**production-ready**)
- `EmailPasswordAuthProvider` – for email/password login (demo/prototyping)

> **You are expected to implement your own `AuthProvider` for your backend, except for anonymous flows.**

### Example: Custom AuthProvider

```dart
class MyProvider extends AuthProvider {
  @override
  String get providerId => 'my_provider';

  @override
  Future<AuthResult> login(Map<String, dynamic> credentials) async {
    // Your authentication logic here
    return AuthResult(user: customUser, token: customToken);
  }
}
```

Register your provider:

```dart
await AuthManager().configure(AuthConfig(
  providers: [MyProvider(), AnonymousAuthProvider()],
  defaultProviderId: 'my_provider',
  storage: SecureAuthStorage.withDefaultUser(),
));
```

---

## 👤 User Model Options

- **Default:** `DefaultAuthUser` (minimal, can be used as-is)
- **Custom:** Extend `AuthUser` to match your API

> **Important:** If you use a custom user model, you must configure it in `SecureAuthStorage` by passing a custom deserializer. By default, `SecureAuthStorage.withDefaultUser()` is used, which only supports `DefaultAuthUser`.

```dart
final storage = SecureAuthStorage(
  userDeserializer: (data) => MyUser.deserialize(data),
);
```

---

## 💾 Storage Options

- **Default:** `SecureAuthStorage` (uses `shared_preferences`)
- **Custom:** Implement `AuthStorage` for your own persistence

---

## 🛠️ Configuration Example

```dart
final myProvider = MyProvider();
final anonProvider = AnonymousAuthProvider();
await AuthManager().configure(AuthConfig(
  providers: [myProvider, anonProvider],
  defaultProviderId: 'my_provider',
  storage: SecureAuthStorage.withDefaultUser(),
));
```

---

## 🔄 Usage

### Login

```dart
final result = await AuthManager().loginWithProvider('my_provider', {
  'email': 'user@example.com',
  'password': 'secret',
});
final user = result.user;
final token = result.token;
```

### Manual Session

```dart
await AuthManager().setSession(user, token, providerId: 'my_provider');
```

### Logout

```dart
await AuthManager().logout();
```

### Auth State & Streams

```dart
final isLoggedIn = AuthManager().isAuthenticated;
final user = AuthManager().currentUser;
final token = AuthManager().currentToken;
AuthManager().statusStream.listen((status) { ... });
AuthManager().userStream.listen((user) { ... });
AuthManager().tokenStream.listen((token) { ... });
```

### Global Events

```dart
AuthEventBus().onLogin((event) { ... });
AuthEventBus().onLogout((event) { ... });
```

### Token Refresh 🔄

AuthFlow supports automatic and manual token refresh:

```dart
// Configure auto-refresh (enabled by default)
await AuthManager().configure(AuthConfig(
  providers: [MyProvider()],
  autoRefreshOnExpiry: true, // Automatically refresh expired tokens
));

// Manual refresh
try {
  final newToken = await AuthManager().refreshSession();
  if (newToken != null) {
    print('Token refreshed successfully');
  } else {
    print('Refresh not supported by current provider');
  }
} catch (e) {
  print('Refresh failed: $e');
}

// Listen for refresh events
AuthEventBus().events.listen((event) {
  if (event is TokenRefreshEvent) {
    if (event.isSuccess) {
      print('Token refreshed for user ${event.user.id}');
    } else {
      print('Refresh failed: ${event.error}');
    }
  }
});
```

**Implementing refresh in your provider:**

```dart
class MyProvider extends AuthProvider {
  @override
  Future<AuthToken?> refreshToken(AuthToken currentToken, AuthUser user) async {
    // Make API call to refresh token
    final response = await _api.refreshToken(currentToken.refreshToken);

    if (response.isSuccess) {
      return AuthToken(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresAt: response.expiresAt,
      );
    }

    return null; // Refresh failed or not supported
  }
}
```

---

## 🧩 Flutter UI Integration

Use `AuthBuilder` to rebuild UI based on authentication state:

```dart
AuthBuilder(
  authenticated: (context, user, token) => HomeScreen(user: user),
  unauthenticated: (context) => LoginScreen(),
  loading: (context) => LoadingScreen(),
  // Optional: Control when rebuilds happen
  buildWhen: (previous, current) {
    // Don't rebuild during login attempts
    if (current.status == AuthStatus.loading && previous.status != AuthStatus.loading) {
      return false;
    }
    return true;
  },
);
```

> **Tip:** The `buildWhen` parameter helps prevent UI flashing during authentication state changes.

---

## 🛡️ Error Handling

Authflow provides a standardized exception system with `AuthException`:

```dart
try {
  final result = await AuthManager().login({ ... });
} on AuthException catch (e) {
  print('Error type: \\${e.type}');
  print('Error message: \\${e.message}');
}
```

See the docs for available exception types and customization.

---

## ❓ FAQ

**Q: Is Authflow a plug-and-play backend auth solution?**  
A: No. You must implement your own `AuthProvider` for your backend.

**Q: Can I use my own user model?**  
A: Yes! Just extend `AuthUser`.

**Q: Can I use my own storage?**  
A: Yes! Just implement `AuthStorage`.

**Q: What does Authflow actually do for me?**  
A: It manages the flow, state, and persistence of authentication, so you can focus on your business logic.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Firuz Vorisov**  
[github.com/vfiruz97](https://github.com/vfiruz97)

Feel free to open issues or contribute via PR!
