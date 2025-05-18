import 'dart:convert';

/// Abstract class representing a user model for authentication.
/// Extend this class to implement a custom user model that fits your API structure.
abstract class AuthUser {
  /// Unique identifier for the user
  String get id;

  /// Email address of the user (if available)
  String? get email;

  /// Display name or username (if available)
  String? get displayName;

  /// Converts the user to a JSON map
  Map<String, dynamic> toJson();

  /// Serializes the user to a JSON string
  String serialize() => jsonEncode(toJson());

  /// Whether this user is considered anonymous
  bool get isAnonymous => false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Default implementation of [AuthUser] with minimal properties.
/// Can be extended or replaced with a custom implementation.
class DefaultAuthUser extends AuthUser {
  @override
  final String id;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  final bool isAnonymous;

  /// Creates a new [DefaultAuthUser] instance
  DefaultAuthUser({required this.id, this.email, this.displayName, this.isAnonymous = false});

  /// Creates a new [DefaultAuthUser] from JSON data
  factory DefaultAuthUser.fromJson(Map<String, dynamic> json) {
    return DefaultAuthUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'displayName': displayName, 'isAnonymous': isAnonymous};
  }

  /// Creates a new [DefaultAuthUser] from a serialized JSON string
  factory DefaultAuthUser.deserialize(String serialized) {
    return DefaultAuthUser.fromJson(jsonDecode(serialized) as Map<String, dynamic>);
  }

  /// Creates a copy of this user with the given fields replaced with new values
  DefaultAuthUser copyWith({String? id, String? email, String? displayName, bool? isAnonymous}) {
    return DefaultAuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}
