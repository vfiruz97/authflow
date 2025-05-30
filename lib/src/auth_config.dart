import 'auth_exception.dart';
import 'auth_provider.dart';
import 'auth_registry.dart';
import 'auth_storage.dart';
import 'storage/secure_auth_storage.dart';

/// Configuration for the AuthManager.
class AuthConfig {
  /// The list of available authentication providers
  final List<AuthProvider> providers;

  /// The ID of the default authentication provider
  ///
  /// If not specified, the first provider in the list will be used.
  ///
  /// Important: This enables AuthManager().login() to use this provider
  final String? defaultProviderId;

  /// The storage implementation to use for persisting authentication state
  final AuthStorage storage;

  /// Whether to automatically attempt token refresh when the access token expires
  ///
  /// When enabled, AuthManager will automatically try to refresh expired tokens
  /// using the provider's [AuthProvider.refreshToken] method during session
  /// restoration.
  ///
  /// Defaults to true for seamless user experience.
  final bool autoRefreshOnExpiry;

  /// Creates a new [AuthConfig] with the given options
  AuthConfig({
    required this.providers,
    this.defaultProviderId,
    AuthStorage? storage,
    this.autoRefreshOnExpiry = true,
  }) : storage = storage ?? SecureAuthStorage.withDefaultUser() {
    // Register all providers in the global registry
    final registry = AuthRegistry();
    for (final provider in providers) {
      registry.register(provider);
    }
  }

  /// Gets the default provider to use for authentication
  ///
  /// Returns the provider with the specified default ID, or the first provider
  /// in the list if no default ID is specified.
  ///
  /// Throws an exception if no providers are registered or if the default
  /// provider ID is specified but not found.
  AuthProvider getDefaultProvider() {
    final registry = AuthRegistry();
    if (providers.isEmpty) {
      throw AuthException.provider(
        'default',
        Exception('No providers available'),
        'No authentication providers registered',
      );
    }

    if (defaultProviderId != null) {
      final provider = registry.getProvider(defaultProviderId!);
      if (provider == null) {
        throw AuthException.provider(
          defaultProviderId!,
          Exception('Provider not found'),
          'Default provider not found: $defaultProviderId',
        );
      }
      return provider;
    }

    return providers.first;
  }
}
