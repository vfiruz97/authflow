import 'dart:convert';

import 'package:authflow/authflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

/// Enhanced HTTP-based authentication provider that demonstrates a more realistic
/// authentication flow with proper error handling and multiple user support.
class HttpEmailPasswordAuthProvider extends EmailPasswordAuthProvider {
  final String loginUrl;

  HttpEmailPasswordAuthProvider({required this.loginUrl});

  @override
  Future<AuthResult> authenticate(EmailPasswordCredentials credentials) async {
    try {
      final response = await http.get(Uri.parse("$loginUrl/${credentials.email}.json"));
      final data = Map<String, dynamic>.from(jsonDecode(response.body));
      final user = Map<String, dynamic>.from(data['user'] ?? {});
      final token = Map<String, dynamic>.from(data['token'] ?? {});

      if (user['email'] != credentials.email || user['password'] != credentials.password) {
        throw AuthException.credentials('Invalid email or password');
      }

      final authUser = DefaultAuthUser(id: user['id'], email: user['email'], displayName: user['displayName']);
      final authToken = AuthToken(accessToken: token['accessToken']);

      return AuthResult(user: authUser, token: authToken);
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
    // Create auth providers
    final anonymousProvider = AnonymousAuthProvider();
    final emailProvider = HttpEmailPasswordAuthProvider(
      loginUrl: 'https://github.com/vfiruz97/authflow/tree/dev/example/assets',
    );

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
        return const LoginScreen();
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
  List<Map<String, dynamic>> _availableUsers = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
  }

  Future<void> _loadAvailableUsers() async {
    try {
      final jsonString = await rootBundle.loadString('assets/credentials.json');
      final data = jsonDecode(jsonString);
      final users = List<Map<String, dynamic>>.from(data['users']);

      if (mounted) {
        setState(() {
          _availableUsers = users;
        });
      }
    } catch (e) {
      // Handle error silently - this is just a convenience feature
      print('Could not load available users: $e');
    }
  }

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
      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unexpected error: ${e.toString()}';
        });
      }
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
      if (mounted) {
        setState(() {
          _errorMessage = 'Login failed: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unexpected error: ${e.toString()}';
        });
      }
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
      appBar: AppBar(title: const Text('Authflow Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo or title area
                      const Icon(Icons.lock_outline, size: 64, color: Colors.deepPurple),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome to Authflow',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'A flexible authentication package',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Error message area
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900)),
                        ),

                      // Login form
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock_outlined),
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loginWithEmailPassword,
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                                child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Available users section
                      if (_availableUsers.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Available Demo Users',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_availableUsers.length, (index) {
                          final user = _availableUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(user['email']),
                              subtitle: Text('Password: ${user['password']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.login),
                                onPressed: () {
                                  setState(() {
                                    _emailController.text = user['email'];
                                    _passwordController.text = user['password'];
                                  });
                                },
                              ),
                            ),
                          );
                        }),
                      ],

                      // Alternative login options
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _loginAnonymously,
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Continue as Guest'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ],
                  ),
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
        title: const Text('Authflow Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              try {
                await AuthManager().logout();
              } on AuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout error: ${e.message}')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Unexpected error: ${e.toString()}')));
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Text(
              'Welcome, ${user.displayName ?? user.email ?? 'User ${user.id}'}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text('You are now logged in with Authflow.'),
            const SizedBox(height: 8),
            if (user.isAnonymous)
              const Text(
                'You are using a guest account. Your session will expire in 7 days.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 24),

            // User information card
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

            // Token information card with StreamBuilder
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

            const SizedBox(height: 16),

            // Auth status card
            StreamBuilder<AuthStatus>(
              stream: AuthManager().statusStream,
              builder: (context, snapshot) {
                final status = snapshot.data ?? AuthStatus.loading;

                Color statusColor;
                String statusText;

                switch (status) {
                  case AuthStatus.authenticated:
                    statusColor = Colors.green;
                    statusText = 'Authenticated';
                    break;
                  case AuthStatus.unauthenticated:
                    statusColor = Colors.red;
                    statusText = 'Unauthenticated';
                    break;
                  case AuthStatus.loading:
                    statusColor = Colors.orange;
                    statusText = 'Loading';
                    break;
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Auth Status', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Current status: $statusText',
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
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
