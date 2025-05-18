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
final config = AuthConfig(
  providers: {
    'email': EmailPasswordAuthProvider(endpoint: 'https://api.example.com/login'),
    'anonymous': AnonymousAuthProvider(),
  },
  defaultProvider: 'email',
  storage: SecureAuthStorage(),
);

AuthManager().configure(config);
```

---

## 🚀 Usage

### Login

```dart
await AuthManager().login({
  'email': 'user@example.com',
  'password': 'secret',
});
```

### Logout

```dart
await AuthManager().logout();
```

### Listen to Auth State

```dart
AuthManager().statusStream.listen((status) {
  print("Auth status: $status");
});
```

### Get Current User / Token

```dart
final user = AuthManager().currentUser;
final token = AuthManager().currentToken;
```

---

## 🧩 Flutter UI

Use `AuthBuilder` to rebuild UI based on authentication state:

```dart
AuthBuilder(
  builder: (context, status, user) {
    if (status == AuthStatus.authenticated) {
      return HomeScreen(user: user);
    } else {
      return LoginScreen();
    }
  },
)
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

## 📂 Project Structure

See [ARCHITECTURE.md](ARCHITECTURE.md) for a full breakdown of internal structure and contribution guidelines.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Firuz Vorisov**  
[github.com/vfiruz97](https://github.com/vfiruz97)

Feel free to open issues or contribute via PR!
