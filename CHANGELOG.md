## 1.1.0 - May 30, 2025

- Added `imageUrl` property to `DefaultAuthUser`

### ✨ Token Refresh Feature

- **Added token refresh functionality to `AuthProvider` interface**
  - New `refreshToken` method with default implementation returning `null`
  - Allows providers to implement custom token refresh logic
- **Enhanced `AuthManager` with refresh capabilities**
  - New `refreshSession()` method for manual token refresh
  - Automatic token refresh during session restoration when enabled
- **Added configuration control via `AuthConfig`**
  - New `autoRefreshOnExpiry` flag (defaults to `true`)
  - Enables/disables automatic refresh on expired tokens
- **New `TokenRefreshEvent` for refresh tracking**
  - Success and failure events with detailed information
  - Integrates with existing event bus system

## 1.0.2 - May 28, 2025

- Update SDK to `>=3.0.0 <4.0.0` and flutter to `>=3.7.0` in pubspec.yaml

## 1.0.1 - May 28, 2025

- Improved Readme documentation with quickstart guide and built-in providers

## 1.0.0 - May 25, 2025

- Fixed `AuthManager.login()` to properly respect `defaultProviderId` from `AuthConfig`
- Implemented standardized exception handling with `AuthException` class
- Added typed exception factory constructors for various authentication scenarios
- Updated providers to use consistent error handling
- Improved testing for exception cases
- Enhanced error reporting with contextual information
- Added test mode support to `AuthEventBus` for improved testability
- Fixed event handling in tests to avoid cross-test interference
- Add optional expiration duration for anonymous sessions in AnonymousAuthProvider
- Improved documentation and examples for exception handling
- Enhanced `AuthBuilder` with optimized stream handling and token expiration check

## 0.0.1 - May 19, 2025

Initial release of the Authflow package with the following features:

### Core Components

- `AuthToken`: Token management with access token, refresh token, and expiration handling
- `AuthUser`: Abstract user model with `DefaultAuthUser` implementation
- `AuthStorage`: Interface for persisting authentication state
- `SecureAuthStorage`: Implementation using SharedPreferences for secure storage
- `AuthProvider`: Abstract interface for authentication providers
- `AuthStatus`: Enum representing authentication states (authenticated, unauthenticated, loading)
- `AuthRegistry`: Global registry for managing authentication providers
- `AuthManager`: Central orchestrator for authentication operations
- `AuthConfig`: Configuration system for the auth manager
- `AuthEventBus`: Reactive event system using RxDart's BehaviorSubject for auth state changes

### Authentication Providers

- `AnonymousAuthProvider`: Provider for anonymous authentication
- `EmailPasswordAuthProvider`: Base provider for email/password authentication
- `MockEmailPasswordAuthProvider`: Implementation for testing or demos

### Events

- `LoginEvent`: Dispatched when a user logs in
- `LogoutEvent`: Dispatched when a user logs out

### Flutter Widgets

- `AuthBuilder`: Stream-based widget for building UIs based on auth state

### Features

- Multiple authentication provider support
- Reactive streams for auth status, user, and token
- Secure token and user persistence
- Manual session injection capabilities
- Global event system for cross-app auth state management
