import 'package:json_annotation/json_annotation.dart';

part 'oauth_config.g.dart';

/// Storage type options for token and user data persistence
enum StorageType {
  /// Use flutter_secure_storage (recommended for production)
  secure,
  /// Use shared_preferences (fallback option)
  sharedPreferences,
  /// Use Hive database (for compatibility with existing apps)
  hive,
}

/// Configuration for Frappe OAuth2 authentication
/// 
/// Contains all necessary configuration for OAuth2 flow including
/// server endpoints, client credentials, and SDK behavior settings.
@JsonSerializable()
class OAuthConfig {
  /// Base URL of the Frappe server (e.g., 'https://your-site.frappe.cloud')
  final String baseUrl;

  /// OAuth2 client ID registered in Frappe
  final String clientId;

  /// Custom URL scheme for redirect (e.g., 'myapp')
  final String redirectScheme;

  /// OAuth2 scopes to request (defaults to ['all', 'openid'])
  final List<String> scopes;

  /// How long before expiration to refresh tokens (defaults to 5 minutes)
  @JsonKey(fromJson: _durationFromJson, toJson: _durationToJson)
  final Duration tokenRefreshThreshold;

  /// Whether to automatically refresh tokens in the background
  final bool autoRefresh;

  /// Storage type for tokens and user data
  final StorageType storageType;

  /// Custom authorization endpoint (if different from default)
  final String? customAuthorizationEndpoint;

  /// Custom token endpoint (if different from default)
  final String? customTokenEndpoint;

  /// Custom user info endpoint (if different from default)
  final String? customUserInfoEndpoint;

  /// Additional parameters to include in authorization request
  final Map<String, String> additionalAuthParams;

  /// Timeout for network requests (defaults to 30 seconds)
  @JsonKey(fromJson: _durationFromJson, toJson: _durationToJson)
  final Duration networkTimeout;

  /// Whether to enable debug logging
  final bool enableLogging;

  const OAuthConfig({
    required this.baseUrl,
    required this.clientId,
    required this.redirectScheme,
    this.scopes = const ['all', 'openid'],
    this.tokenRefreshThreshold = const Duration(minutes: 5),
    this.autoRefresh = true,
    this.storageType = StorageType.secure,
    this.customAuthorizationEndpoint,
    this.customTokenEndpoint,
    this.customUserInfoEndpoint,
    this.additionalAuthParams = const {},
    this.networkTimeout = const Duration(seconds: 30),
    this.enableLogging = false,
  });

  /// Creates an OAuthConfig from JSON
  factory OAuthConfig.fromJson(Map<String, dynamic> json) =>
      _$OAuthConfigFromJson(json);

  /// Converts OAuthConfig to JSON
  Map<String, dynamic> toJson() => _$OAuthConfigToJson(this);

  /// Gets the redirect URI for OAuth2 flow
  String get redirectUri => '$redirectScheme://oauth2redirect';

  /// Gets the authorization endpoint URL
  String get authorizationEndpoint {
    return customAuthorizationEndpoint ??
        '$baseUrl/api/method/frappe.integrations.oauth2.authorize';
  }

  /// Gets the token endpoint URL
  String get tokenEndpoint {
    return customTokenEndpoint ??
        '$baseUrl/api/method/frappe.integrations.oauth2.get_token';
  }

  /// Gets the user info endpoint URL
  String get userInfoEndpoint {
    return customUserInfoEndpoint ??
        '$baseUrl/api/method/frappe.integrations.oauth2.openid_profile';
  }

  /// Gets the scopes as a space-separated string
  String get scopeString => scopes.join(' ');

  /// Validates the configuration and returns a list of issues
  List<String> validate() {
    final issues = <String>[];

    // Validate base URL
    if (baseUrl.isEmpty) {
      issues.add('Base URL cannot be empty');
    } else {
      final uri = Uri.tryParse(baseUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        issues.add('Base URL must be a valid URL with scheme and host');
      } else if (!['http', 'https'].contains(uri.scheme)) {
        issues.add('Base URL must use http or https scheme');
      }
    }

    // Validate client ID
    if (clientId.isEmpty) {
      issues.add('Client ID cannot be empty');
    }

    // Validate redirect scheme
    if (redirectScheme.isEmpty) {
      issues.add('Redirect scheme cannot be empty');
    } else if (redirectScheme.contains('://')) {
      issues.add('Redirect scheme should not contain ://');
    } else if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*$').hasMatch(redirectScheme)) {
      issues.add('Redirect scheme must be a valid URL scheme');
    }

    // Validate scopes
    if (scopes.isEmpty) {
      issues.add('At least one scope must be specified');
    }

    // Validate thresholds
    if (tokenRefreshThreshold.isNegative) {
      issues.add('Token refresh threshold cannot be negative');
    }

    if (networkTimeout.isNegative || networkTimeout.inSeconds < 1) {
      issues.add('Network timeout must be at least 1 second');
    }

    return issues;
  }

  /// Checks if the configuration is valid
  bool get isValid => validate().isEmpty;

  /// Creates a copy of this OAuthConfig with updated fields
  OAuthConfig copyWith({
    String? baseUrl,
    String? clientId,
    String? redirectScheme,
    List<String>? scopes,
    Duration? tokenRefreshThreshold,
    bool? autoRefresh,
    StorageType? storageType,
    String? customAuthorizationEndpoint,
    String? customTokenEndpoint,
    String? customUserInfoEndpoint,
    Map<String, String>? additionalAuthParams,
    Duration? networkTimeout,
    bool? enableLogging,
  }) {
    return OAuthConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      clientId: clientId ?? this.clientId,
      redirectScheme: redirectScheme ?? this.redirectScheme,
      scopes: scopes ?? this.scopes,
      tokenRefreshThreshold: tokenRefreshThreshold ?? this.tokenRefreshThreshold,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      storageType: storageType ?? this.storageType,
      customAuthorizationEndpoint: customAuthorizationEndpoint ?? this.customAuthorizationEndpoint,
      customTokenEndpoint: customTokenEndpoint ?? this.customTokenEndpoint,
      customUserInfoEndpoint: customUserInfoEndpoint ?? this.customUserInfoEndpoint,
      additionalAuthParams: additionalAuthParams ?? this.additionalAuthParams,
      networkTimeout: networkTimeout ?? this.networkTimeout,
      enableLogging: enableLogging ?? this.enableLogging,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OAuthConfig &&
        other.baseUrl == baseUrl &&
        other.clientId == clientId &&
        other.redirectScheme == redirectScheme;
  }

  @override
  int get hashCode {
    return baseUrl.hashCode ^ clientId.hashCode ^ redirectScheme.hashCode;
  }

  @override
  String toString() {
    return 'OAuthConfig(baseUrl: $baseUrl, clientId: $clientId, '
           'redirectScheme: $redirectScheme, scopes: $scopes)';
  }

  // Helper methods for JSON serialization of Duration
  static Duration _durationFromJson(int milliseconds) =>
      Duration(milliseconds: milliseconds);

  static int _durationToJson(Duration duration) => duration.inMilliseconds;
}
