import 'package:json_annotation/json_annotation.dart';

part 'token_response.g.dart';

/// Represents an OAuth2 token response from Frappe server
/// 
/// Contains access token, refresh token, and expiration information
/// with utility methods for token validation and expiration checking.
@JsonSerializable()
class TokenResponse {
  /// The access token used for API authentication
  @JsonKey(name: 'access_token')
  final String accessToken;

  /// The refresh token used to obtain new access tokens
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  /// Token expiration time in seconds from issuance
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  /// Token type (usually "Bearer")
  @JsonKey(name: 'token_type')
  final String tokenType;

  /// Timestamp when the token was issued
  @JsonKey(name: 'issued_at')
  final DateTime issuedAt;

  /// OAuth2 scopes granted to this token
  final List<String>? scope;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
    required this.issuedAt,
    this.scope,
  });

  /// Creates a TokenResponse from JSON
  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    // Handle the case where issued_at might not be in the response
    final now = DateTime.now();
    final issuedAt = json['issued_at'] != null 
        ? DateTime.parse(json['issued_at'] as String)
        : now;
    
    // Handle scope as either string or list
    List<String>? scopeList;
    if (json['scope'] != null) {
      if (json['scope'] is String) {
        scopeList = (json['scope'] as String).split(' ');
      } else if (json['scope'] is List) {
        scopeList = (json['scope'] as List).cast<String>();
      }
    }
    
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      issuedAt: issuedAt,
      scope: scopeList,
    );
  }

  /// Converts TokenResponse to JSON
  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);

  /// Calculates the exact expiration time
  DateTime get expiresAt => issuedAt.add(Duration(seconds: expiresIn));

  /// Checks if the token is currently expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Checks if the token is expiring soon (within 5 minutes by default)
  bool isExpiringSoon([Duration threshold = const Duration(minutes: 5)]) {
    return DateTime.now().isAfter(expiresAt.subtract(threshold));
  }

  /// Returns the remaining time until expiration
  Duration get timeUntilExpiration {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return Duration.zero;
    }
    return expiresAt.difference(now);
  }

  /// Checks if the token is valid (not expired and has required fields)
  bool get isValid {
    return accessToken.isNotEmpty && 
           refreshToken.isNotEmpty && 
           !isExpired;
  }

  /// Creates a copy of this TokenResponse with updated fields
  TokenResponse copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
    String? tokenType,
    DateTime? issuedAt,
    List<String>? scope,
  }) {
    return TokenResponse(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
      tokenType: tokenType ?? this.tokenType,
      issuedAt: issuedAt ?? this.issuedAt,
      scope: scope ?? this.scope,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TokenResponse &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.expiresIn == expiresIn &&
        other.tokenType == tokenType &&
        other.issuedAt == issuedAt;
  }

  @override
  int get hashCode {
    return accessToken.hashCode ^
        refreshToken.hashCode ^
        expiresIn.hashCode ^
        tokenType.hashCode ^
        issuedAt.hashCode;
  }

  @override
  String toString() {
    return 'TokenResponse(tokenType: $tokenType, expiresIn: $expiresIn, '
           'isExpired: $isExpired, expiresAt: $expiresAt)';
  }
}
