import 'package:authflow/authflow.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
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
    // Create auth providers
    final anonymousProvider = AnonymousAuthProvider();
    final emailProvider = MockEmailPasswordAuthProvider();

    // Configure the AuthManager
    await AuthManager().configure(
      AuthConfig(providers: [anonymousProvider, emailProvider], storage: SecureAuthStorage.withDefaultUser()),
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
    return AuthBuilder(
      authenticated: (context, user, token) {
        return HomeScreen(user: user);
      },
      unauthenticated: (context) {
        return LoginScreen();
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmailPassword() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password are required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthManager().loginWithProvider('email_password', {
        'email': _emailController.text,
        'password': _passwordController.text,
      });
    } on AuthException catch (e) {
      setState(() {
        // Handle specific exception types differently
        switch (e.type) {
          case AuthExceptionType.credentials:
            _errorMessage = 'Invalid or missing credentials: ${e.message}';
            break;
          case AuthExceptionType.provider:
            _errorMessage = 'Provider error: ${e.message}';
            break;
          case AuthExceptionType.custom:
            _errorMessage = 'Custom error: ${e.message}';
            break;
          case AuthExceptionType.unknown:
            _errorMessage = 'Unknown error: ${e.message}';
            break;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthManager().loginWithProvider('anonymous', {});
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
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
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.red.shade100,
                        child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900)),
                      ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 24),
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

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await AuthManager().logout();
              } on AuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout error: ${e.message}')));
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Unexpected error: ${e.toString()}')));
              }
            },
          ),
        ],
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
            const Text('You are now logged in.'),
            const SizedBox(height: 8),
            if (user.isAnonymous)
              const Text(
                'You are using a guest account. Your session will expire in 7 days.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('ID: ${user.id}'),
                    if (user.email != null) Text('Email: ${user.email}'),
                    if (user.displayName != null) Text('Name: ${user.displayName}'),
                    Text('Anonymous: ${user.isAnonymous}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<AuthToken?>(
              stream: AuthManager().tokenStream,
              builder: (context, snapshot) {
                final token = snapshot.data;
                if (token == null) {
                  return const Text('No token available');
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Token Information', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Access Token: ${_formatToken(token.accessToken)}'),
                        if (token.refreshToken != null) Text('Refresh Token: ${_formatToken(token.refreshToken!)}'),
                        if (token.expiresAt != null) Text('Expires: ${token.expiresAt!.toLocal()}'),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${token.isExpired ? 'Expired' : 'Valid'}',
                          style: TextStyle(
                            color: token.isExpired ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatToken(String token) {
    if (token.length <= 8) return token;
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }
}
