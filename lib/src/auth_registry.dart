import 'auth_provider.dart';

/// Global registry for authentication providers.
class AuthRegistry {
  /// Singleton instance
  static final AuthRegistry _instance = AuthRegistry._();

  /// Map of provider ID to provider instance
  final Map<String, AuthProvider> _providers = {};

  /// Factory constructor that returns the singleton instance
  factory AuthRegistry() => _instance;

  /// Private constructor for singleton
  AuthRegistry._();

  /// Registers a new authentication provider
  ///
  /// If a provider with the same ID already exists, it will be replaced.
  void register(AuthProvider provider) {
    _providers[provider.providerId] = provider;
  }

  /// Gets a provider by ID
  ///
  /// Returns null if no provider is found with the given ID.
  AuthProvider? getProvider(String providerId) {
    return _providers[providerId];
  }

  /// Gets all registered providers
  List<AuthProvider> get providers => _providers.values.toList();

  /// Gets all registered provider IDs
  List<String> get providerIds => _providers.keys.toList();

  /// Checks if a provider with the given ID is registered
  bool hasProvider(String providerId) {
    return _providers.containsKey(providerId);
  }

  /// Unregisters a provider by ID
  ///
  /// Returns true if a provider was removed, false otherwise.
  bool unregister(String providerId) {
    return _providers.remove(providerId) != null;
  }

  /// Clears all registered providers
  void clear() {
    _providers.clear();
  }
}
