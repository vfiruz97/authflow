import 'dart:convert';

/// Represents authentication tokens with optional refresh token and expiration.
class AuthToken {
  /// The primary access token used for authentication
  final String accessToken;

  /// Optional refresh token for obtaining new access tokens
  final String? refreshToken;

  /// Optional expiration date for the access token
  final DateTime? expiresAt;

  /// Creates a new [AuthToken] instance
  const AuthToken({required this.accessToken, this.refreshToken, this.expiresAt});

  /// Checks if the token has expired
  bool get isExpired {
    final expires = expiresAt;
    if (expires == null) return false;
    return DateTime.now().isAfter(expires);
  }

  /// Creates a new [AuthToken] from JSON data
  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
    );
  }

  /// Converts the token to a JSON map
  Map<String, dynamic> toJson() {
    return {'accessToken': accessToken, 'refreshToken': refreshToken, 'expiresAt': expiresAt?.toIso8601String()};
  }

  /// Serializes the token to a JSON string
  String serialize() => jsonEncode(toJson());

  /// Creates a new [AuthToken] from a serialized JSON string
  factory AuthToken.deserialize(String serialized) {
    return AuthToken.fromJson(jsonDecode(serialized) as Map<String, dynamic>);
  }

  /// Creates a copy of this token with the given fields replaced with new values
  AuthToken copyWith({String? accessToken, String? refreshToken, DateTime? expiresAt}) {
    return AuthToken(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthToken &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => accessToken.hashCode ^ refreshToken.hashCode ^ expiresAt.hashCode;
}
