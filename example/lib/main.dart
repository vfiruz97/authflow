import 'dart:convert';

import 'package:authflow/authflow.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

/// Custom HTTP-based authentication provider that fetches user data from a remote endpoint
class MyCustomEmailPasswordAuthProvider extends EmailPasswordAuthProvider {
  final String baseUrl;

  @override
  // The providerId is a unique identifier for this provider.
  // It's used in AuthManager to find the right provider for login operations.
  // This ID can be referenced in loginWithProvider() calls and is used to match
  // the defaultProviderId in AuthConfig.
  String get providerId => 'my_auth_provider';

  MyCustomEmailPasswordAuthProvider({required this.baseUrl});

  @override
  Future<AuthResult> authenticate(EmailPasswordCredentials credentials) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/${credentials.email}.json"));

      if (response.statusCode != 200) {
        throw AuthException.provider(
          providerId,
          'HTTP Error ${response.statusCode}',
          'Server returned ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);
      final user = data['user'];

      return AuthResult(
        user: DefaultAuthUser(id: user['id'], email: user['email'], displayName: user['displayName']),
        token: AuthToken(accessToken: data['token']['accessToken'], refreshToken: data['token']['refreshToken']),
      );
    } catch (e) {
      throw AuthException.from(e);
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _configureAuth();
  }

  Future<void> _configureAuth() async {
    final anonymousProvider = AnonymousAuthProvider();
    final emailProvider = MyCustomEmailPasswordAuthProvider(
      baseUrl: 'https://raw.githubusercontent.com/vfiruz97/authflow/refs/heads/main/example/assets',
    );

    await AuthManager().configure(
      AuthConfig(
        providers: [anonymousProvider, emailProvider],
        // The defaultProviderId tells AuthManager which provider to use by default
        // when login() is called without specifying a provider ID.
        // This matches the ID from MyCustomEmailPasswordAuthProvider's providerId getter.
        defaultProviderId: 'my_auth_provider',
        // SecureAuthStorage persists user and token data between app restarts.
        // withDefaultUser() configures it to use the DefaultAuthUser implementation.
        // You could also implement a custom AuthStorage for different persistence needs.
        storage: SecureAuthStorage.withDefaultUser(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authflow Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using AuthBuilder to conditionally render based on auth state
    return AuthBuilder(
      // The authenticated callback provides both user and token objects
      authenticated: (context, user, token) => HomeScreen(user: user, token: token),
      // The unauthenticated callback shows the login screen
      unauthenticated: (context) => const LoginScreen(),
      // This buildWhen parameter solves the problem of the login screen disappearing during login attempts.
      // Without it, AuthBuilder would rebuild and show a loading state when logging in,
      // which would cause the login form to vanish temporarily.
      buildWhen: (previous, current) {
        // Don't rebuild during login attempts (when going from authenticated/unauthenticated to loading)
        if (current.status == AuthStatus.loading && previous.status != AuthStatus.loading) {
          return false;
        }
        // Otherwise, rebuild on state changes
        return true;
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'user@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper method to handle login attempts
  Future<void> _performLogin(Future<void> Function() loginFunction) async {
    // Set loading state and clear previous errors
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Perform the login operation
      await loginFunction();
    } catch (e) {
      // Handle errors if the widget is still mounted
      if (mounted) {
        setState(() {
          _errorMessage = switch (e) {
            AuthException ae => 'Auth error (${ae.type}): ${ae.message}',
            _ => 'Error: ${e.toString()}',
          };
        });
      }
    } finally {
      // Reset loading state if the widget is still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Login with email/password using the default provider
  Future<void> _loginWithEmailPassword() async {
    await _performLogin(() {
      // Uses the default provider (configured as 'my_auth_provider')
      // AuthManager.login() automatically uses the defaultProviderId from configuration
      return AuthManager().login({'email': _emailController.text, 'password': _passwordController.text});
    });
  }

  // Login anonymously using the anonymous provider
  Future<void> _loginAnonymously() async {
    await _performLogin(() {
      // Uses a specific provider by ID rather than the default
      // This approach allows you to use any registered provider explicitly
      return AuthManager().loginWithProvider('anonymous', {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authflow Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.red.shade100,
                        child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900)),
                      ),

                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loginWithEmailPassword, child: const Text('Login')),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: _loginAnonymously, child: const Text('Continue as Guest')),
                  ],
                ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final AuthUser user;
  final AuthToken token;

  const HomeScreen({super.key, required this.user, required this.token});

  // Helper to create info cards
  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  // Format token for display (show first and last 4 chars)
  String _formatToken(String token) {
    if (token.length <= 8) return token;
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authflow Demo'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => AuthManager().logout())],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user.displayName ?? user.email ?? 'User ${user.id}'}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // User information card
            _buildInfoCard('User Information', [
              Text('ID: ${user.id}'),
              if (user.email != null) Text('Email: ${user.email}'),
              if (user.displayName != null) Text('Name: ${user.displayName}'),
              Text('Anonymous: ${user.isAnonymous}'),
            ]),

            const SizedBox(height: 16),

            // Token information card
            _buildInfoCard('Token Information', [
              Text('Access Token: ${_formatToken(token.accessToken)}'),
              if (token.refreshToken != null) Text('Refresh Token: ${_formatToken(token.refreshToken!)}'),
              if (token.expiresAt != null) Text('Expires: ${token.expiresAt!.toString()}'),
            ]),
          ],
        ),
      ),
    );
  }
}
