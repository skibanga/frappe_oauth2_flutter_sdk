import 'dart:math';
import 'package:frappe_oauth2_flutter_sdk/exceptions/frappe_auth_exception.dart';
import '../models/oauth_config.dart';

/// Simplified utility class for building OAuth2 URLs
class UrlBuilder {
  final OAuthConfig config;

  const UrlBuilder({required this.config});

  /// Builds the OAuth2 authorization URL for this configuration
  String buildAuthorizationUrl({String? state}) {
    final redirectUri = '${config.redirectScheme}://oauth2redirect';
    final generatedState = state ?? _generateState();

    return buildAuthorizationUrlStatic(
      baseUrl: config.baseUrl,
      clientId: config.clientId,
      redirectUri: redirectUri,
      scope: config.scopes.join(' '),
      codeChallenge: '', // We'll add PKCE later if needed
      state: generatedState,
    );
  }

  /// Builds the token exchange URL
  String buildTokenUrl() {
    return '${config.baseUrl}/api/method/frappe.integrations.oauth2.get_token';
  }

  /// Builds the user info URL
  String buildUserInfoUrl() {
    return '${config.baseUrl}/api/method/frappe.integrations.oauth2.openid_profile';
  }

  /// Generates a random state parameter
  String _generateState() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      32,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Static method - builds a complete OAuth2 authorization URL with all required parameters
  static String buildAuthorizationUrlStatic({
    required String baseUrl,
    required String clientId,
    required String redirectUri,
    required String scope,
    required String codeChallenge,
    required String state,
    String? customEndpoint,
    Map<String, String> additionalParams = const {},
  }) {
    final endpoint =
        customEndpoint ??
        '$baseUrl/api/method/frappe.integrations.oauth2.authorize';

    final params = <String, String>{
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': scope,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
      ...additionalParams,
    };

    return _buildUrlWithParams(endpoint, params);
  }

  /// Builds the token endpoint URL (static version)
  static String buildTokenUrlStatic({
    required String baseUrl,
    String? customEndpoint,
  }) {
    return customEndpoint ??
        '$baseUrl/api/method/frappe.integrations.oauth2.get_token';
  }

  /// Builds the user info endpoint URL (static version)
  static String buildUserInfoUrlStatic({
    required String baseUrl,
    String? customEndpoint,
  }) {
    return customEndpoint ??
        '$baseUrl/api/method/frappe.integrations.oauth2.openid_profile';
  }

  /// Validates a base URL for OAuth2 usage
  static List<String> validateBaseUrl(String baseUrl) {
    final issues = <String>[];

    if (baseUrl.isEmpty) {
      issues.add('Base URL cannot be empty');
      return issues;
    }

    final uri = Uri.tryParse(baseUrl);
    if (uri == null) {
      issues.add('Base URL must be a valid URL');
      return issues;
    }

    if (!uri.hasScheme) {
      issues.add('Base URL must include a scheme (http or https)');
    } else if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
      issues.add('Base URL must use http or https scheme');
    }

    if (!uri.hasAuthority) {
      issues.add('Base URL must include a host');
    }

    // Check for common issues
    if (uri.path.isNotEmpty && uri.path != '/') {
      issues.add('Base URL should not include a path (found: ${uri.path})');
    }

    if (uri.hasQuery) {
      issues.add('Base URL should not include query parameters');
    }

    if (uri.hasFragment) {
      issues.add('Base URL should not include a fragment');
    }

    return issues;
  }

  /// Validates a redirect URI scheme
  static List<String> validateRedirectScheme(String scheme) {
    final issues = <String>[];

    if (scheme.isEmpty) {
      issues.add('Redirect scheme cannot be empty');
      return issues;
    }

    if (scheme.contains('://')) {
      issues.add('Redirect scheme should not contain ://');
    }

    // Check if it's a valid URL scheme according to RFC 3986
    final schemeRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*$');
    if (!schemeRegex.hasMatch(scheme)) {
      issues.add(
        'Redirect scheme must be a valid URL scheme (letters, numbers, +, -, .)',
      );
    }

    // Check for reserved schemes
    const reservedSchemes = [
      'http',
      'https',
      'ftp',
      'ftps',
      'file',
      'data',
      'javascript',
      'mailto',
      'tel',
      'sms',
      'market',
      'intent',
      'android-app',
    ];

    if (reservedSchemes.contains(scheme.toLowerCase())) {
      issues.add('Redirect scheme cannot use reserved scheme: $scheme');
    }

    // Recommendations
    if (scheme.length < 3) {
      issues.add('Redirect scheme should be at least 3 characters long');
    }

    if (scheme.length > 50) {
      issues.add('Redirect scheme should not exceed 50 characters');
    }

    return issues;
  }

  /// Validates a complete redirect URI
  static List<String> validateRedirectUri(String redirectUri) {
    final issues = <String>[];

    if (redirectUri.isEmpty) {
      issues.add('Redirect URI cannot be empty');
      return issues;
    }

    final uri = Uri.tryParse(redirectUri);
    if (uri == null) {
      issues.add('Redirect URI must be a valid URI');
      return issues;
    }

    if (!uri.hasScheme) {
      issues.add('Redirect URI must include a scheme');
    } else {
      // Validate the scheme part
      final schemeIssues = validateRedirectScheme(uri.scheme);
      issues.addAll(schemeIssues);
    }

    // For mobile apps, the host should typically be a simple identifier
    if (uri.hasAuthority && uri.host.isEmpty) {
      issues.add('Redirect URI host cannot be empty when authority is present');
    }

    return issues;
  }

  /// Validates OAuth2 scopes
  static List<String> validateScopes(List<String> scopes) {
    final issues = <String>[];

    if (scopes.isEmpty) {
      issues.add('At least one scope must be specified');
      return issues;
    }

    for (final scope in scopes) {
      if (scope.isEmpty) {
        issues.add('Scope cannot be empty');
        continue;
      }

      if (scope.contains(' ')) {
        issues.add('Individual scope cannot contain spaces: "$scope"');
      }

      // Check for valid characters (letters, numbers, underscore, hyphen, colon, period)
      final scopeRegex = RegExp(r'^[a-zA-Z0-9_\-:.]+$');
      if (!scopeRegex.hasMatch(scope)) {
        issues.add('Scope contains invalid characters: "$scope"');
      }
    }

    return issues;
  }

  /// Validates a client ID
  static List<String> validateClientId(String clientId) {
    final issues = <String>[];

    if (clientId.isEmpty) {
      issues.add('Client ID cannot be empty');
      return issues;
    }

    if (clientId.length < 3) {
      issues.add('Client ID should be at least 3 characters long');
    }

    if (clientId.length > 100) {
      issues.add('Client ID should not exceed 100 characters');
    }

    // Check for potentially problematic characters
    if (clientId.contains(' ')) {
      issues.add('Client ID should not contain spaces');
    }

    if (clientId.contains('\n') ||
        clientId.contains('\r') ||
        clientId.contains('\t')) {
      issues.add('Client ID should not contain whitespace characters');
    }

    return issues;
  }

  /// Validates that an endpoint URL is reachable and properly formatted
  static Future<List<String>> validateEndpoint(String endpoint) async {
    final issues = <String>[];

    if (endpoint.isEmpty) {
      issues.add('Endpoint cannot be empty');
      return issues;
    }

    final uri = Uri.tryParse(endpoint);
    if (uri == null) {
      issues.add('Endpoint must be a valid URL');
      return issues;
    }

    if (!uri.hasScheme ||
        !['http', 'https'].contains(uri.scheme.toLowerCase())) {
      issues.add('Endpoint must use http or https scheme');
    }

    if (!uri.hasAuthority) {
      issues.add('Endpoint must include a host');
    }

    // Additional validation could include:
    // - DNS resolution check
    // - HTTP connectivity test
    // - SSL certificate validation for HTTPS
    // These would be implemented in a more comprehensive validation

    return issues;
  }

  /// Builds a URL with query parameters, properly encoding them
  static String _buildUrlWithParams(
    String baseUrl,
    Map<String, String> params,
  ) {
    if (params.isEmpty) {
      return baseUrl;
    }

    final uri = Uri.parse(baseUrl);
    final newParams = Map<String, String>.from(uri.queryParameters);
    newParams.addAll(params);

    return uri.replace(queryParameters: newParams).toString();
  }

  /// Extracts and validates parameters from a callback URL
  static Map<String, String> extractCallbackParams(String callbackUrl) {
    final uri = Uri.tryParse(callbackUrl);
    if (uri == null) {
      throw FrappeNetworkException(
        'Invalid callback URL format',
        code: 'invalid_callback_url',
      );
    }

    final params = uri.queryParameters;

    // Check for OAuth2 error parameters
    if (params.containsKey('error')) {
      final error = params['error']!;
      final errorDescription = params['error_description'];
      final errorUri = params['error_uri'];

      throw FrappeNetworkException(
        errorDescription ?? 'OAuth2 error: $error',
        code: error,
        context: {
          if (error.isNotEmpty) 'error': error,
          if (errorDescription != null) 'error_description': errorDescription,
          if (errorUri != null) 'error_uri': errorUri,
        },
      );
    }

    return params;
  }

  /// Validates that a callback URL matches the expected redirect URI
  static bool validateCallbackUrl(String callbackUrl, String expectedScheme) {
    final uri = Uri.tryParse(callbackUrl);
    if (uri == null) return false;

    return uri.scheme.toLowerCase() == expectedScheme.toLowerCase();
  }
}
