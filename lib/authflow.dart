/// A flexible, provider-based authentication toolkit for Flutter with
/// stream-based auth state, customizable storage, and composable UI widgets.
library;

// Core components
export 'src/auth_config.dart';
export 'src/auth_event_bus.dart';
export 'src/auth_exception.dart';
export 'src/auth_manager.dart';
export 'src/auth_provider.dart';
export 'src/auth_registry.dart';
export 'src/auth_status.dart';
export 'src/auth_storage.dart';
export 'src/auth_token.dart';
export 'src/auth_user.dart';
// Events
export 'src/events/auth_events.dart';
// Providers
export 'src/providers/anonymous_auth_provider.dart';
export 'src/providers/email_password_auth_provider.dart';
// Storage
export 'src/storage/secure_auth_storage.dart';
// Flutter widgets
export 'src/widgets/auth_builder.dart';
