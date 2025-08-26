import 'package:frappe_oauth2_flutter_sdk/models/oauth_config.dart';
import 'package:frappe_oauth2_flutter_sdk/utils/url_builder.dart';

/// Result of a validation operation
class ValidationResult {
  /// Whether the validation passed
  final bool isValid;

  /// List of validation issues found
  final List<String> issues;

  /// Suggestions for fixing the issues
  final List<String> suggestions;

  /// Additional context about the validation
  final Map<String, dynamic> context;

  const ValidationResult({
    required this.isValid,
    required this.issues,
    this.suggestions = const [],
    this.context = const {},
  });

  /// Creates a successful validation result
  factory ValidationResult.success({
    Map<String, dynamic> context = const {},
  }) {
    return ValidationResult(
      isValid: true,
      issues: [],
      context: context,
    );
  }

  /// Creates a failed validation result
  factory ValidationResult.failure({
    required List<String> issues,
    List<String> suggestions = const [],
    Map<String, dynamic> context = const {},
  }) {
    return ValidationResult(
      isValid: false,
      issues: issues,
      suggestions: suggestions,
      context: context,
    );
  }

  @override
  String toString() {
    if (isValid) {
      return 'ValidationResult: PASSED';
    }

    final buffer = StringBuffer('ValidationResult: FAILED\n');
    buffer.writeln('Issues:');
    for (int i = 0; i < issues.length; i++) {
      buffer.writeln('  ${i + 1}. ${issues[i]}');
    }

    if (suggestions.isNotEmpty) {
      buffer.writeln('\nSuggestions:');
      for (int i = 0; i < suggestions.length; i++) {
        buffer.writeln('  ${i + 1}. ${suggestions[i]}');
      }
    }

    return buffer.toString();
  }
}

/// Utility class for validating OAuth2 configurations and parameters
class ValidationUtils {
  /// Validates a complete OAuth2 configuration
  static ValidationResult validateOAuthConfig(OAuthConfig config) {
    final allIssues = <String>[];
    final suggestions = <String>[];

    // Validate base URL
    final baseUrlIssues = UrlBuilder.validateBaseUrl(config.baseUrl);
    allIssues.addAll(baseUrlIssues);
    if (baseUrlIssues.isNotEmpty) {
      suggestions.add('Ensure base URL is in format: https://your-site.frappe.cloud');
    }

    // Validate client ID
    final clientIdIssues = UrlBuilder.validateClientId(config.clientId);
    allIssues.addAll(clientIdIssues);
    if (clientIdIssues.isNotEmpty) {
      suggestions.add('Check your Frappe OAuth2 client configuration');
    }

    // Validate redirect scheme
    final schemeIssues = UrlBuilder.validateRedirectScheme(config.redirectScheme);
    allIssues.addAll(schemeIssues);
    if (schemeIssues.isNotEmpty) {
      suggestions.add('Use a unique app identifier as redirect scheme (e.g., "myapp")');
    }

    // Validate scopes
    final scopeIssues = UrlBuilder.validateScopes(config.scopes);
    allIssues.addAll(scopeIssues);
    if (scopeIssues.isNotEmpty) {
      suggestions.add('Use valid Frappe scopes like "all", "openid", "profile"');
    }

    // Validate redirect URI
    final redirectUriIssues = UrlBuilder.validateRedirectUri(config.redirectUri);
    allIssues.addAll(redirectUriIssues);

    // Validate timeouts
    if (config.tokenRefreshThreshold.isNegative) {
      allIssues.add('Token refresh threshold cannot be negative');
      suggestions.add('Set token refresh threshold to at least 1 minute');
    }

    if (config.networkTimeout.inSeconds < 1) {
      allIssues.add('Network timeout must be at least 1 second');
      suggestions.add('Set network timeout to at least 10 seconds');
    }

    // Validate custom endpoints if provided
    if (config.customAuthorizationEndpoint != null) {
      final authEndpointIssues = _validateUrl(config.customAuthorizationEndpoint!);
      allIssues.addAll(authEndpointIssues.map((issue) => 'Authorization endpoint: $issue'));
    }

    if (config.customTokenEndpoint != null) {
      final tokenEndpointIssues = _validateUrl(config.customTokenEndpoint!);
      allIssues.addAll(tokenEndpointIssues.map((issue) => 'Token endpoint: $issue'));
    }

    if (config.customUserInfoEndpoint != null) {
      final userInfoEndpointIssues = _validateUrl(config.customUserInfoEndpoint!);
      allIssues.addAll(userInfoEndpointIssues.map((issue) => 'User info endpoint: $issue'));
    }

    if (allIssues.isEmpty) {
      return ValidationResult.success(
        context: {
          'configType': 'oauth2',
          'validatedAt': DateTime.now().toIso8601String(),
        },
      );
    }

    return ValidationResult.failure(
      issues: allIssues,
      suggestions: suggestions,
      context: {
        'configType': 'oauth2',
        'validatedAt': DateTime.now().toIso8601String(),
        'issueCount': allIssues.length,
      },
    );
  }

  /// Validates platform-specific configuration
  static ValidationResult validatePlatformConfig({
    required String platform,
    required String redirectScheme,
    Map<String, dynamic> platformSpecific = const {},
  }) {
    final issues = <String>[];
    final suggestions = <String>[];

    // Validate redirect scheme
    final schemeIssues = UrlBuilder.validateRedirectScheme(redirectScheme);
    issues.addAll(schemeIssues);

    switch (platform.toLowerCase()) {
      case 'android':
        issues.addAll(_validateAndroidConfig(redirectScheme, platformSpecific));
        if (issues.isNotEmpty) {
          suggestions.addAll([
            'Add OAuth redirect activity to AndroidManifest.xml',
            'Ensure intent filter is properly configured',
            'Check that the scheme matches your configuration',
          ]);
        }
        break;

      case 'ios':
        issues.addAll(_validateIOSConfig(redirectScheme, platformSpecific));
        if (issues.isNotEmpty) {
          suggestions.addAll([
            'Add URL scheme to Info.plist',
            'Ensure CFBundleURLSchemes includes your redirect scheme',
            'Check that the scheme is properly registered',
          ]);
        }
        break;

      case 'web':
        issues.addAll(_validateWebConfig(redirectScheme, platformSpecific));
        if (issues.isNotEmpty) {
          suggestions.addAll([
            'Ensure redirect URI is properly configured for web',
            'Check CORS settings on your Frappe server',
            'Verify the redirect URI matches exactly',
          ]);
        }
        break;

      default:
        issues.add('Unsupported platform: $platform');
        suggestions.add('Use one of: android, ios, web');
    }

    if (issues.isEmpty) {
      return ValidationResult.success(
        context: {
          'platform': platform,
          'redirectScheme': redirectScheme,
          'validatedAt': DateTime.now().toIso8601String(),
        },
      );
    }

    return ValidationResult.failure(
      issues: issues,
      suggestions: suggestions,
      context: {
        'platform': platform,
        'redirectScheme': redirectScheme,
        'validatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Validates network connectivity to Frappe endpoints
  static Future<ValidationResult> validateConnectivity(OAuthConfig config) async {
    final issues = <String>[];
    final suggestions = <String>[];

    try {
      // Validate authorization endpoint
      final authIssues = await UrlBuilder.validateEndpoint(config.authorizationEndpoint);
      issues.addAll(authIssues.map((issue) => 'Authorization endpoint: $issue'));

      // Validate token endpoint
      final tokenIssues = await UrlBuilder.validateEndpoint(config.tokenEndpoint);
      issues.addAll(tokenIssues.map((issue) => 'Token endpoint: $issue'));

      // Validate user info endpoint
      final userInfoIssues = await UrlBuilder.validateEndpoint(config.userInfoEndpoint);
      issues.addAll(userInfoIssues.map((issue) => 'User info endpoint: $issue'));

      if (issues.isNotEmpty) {
        suggestions.addAll([
          'Check your internet connection',
          'Verify the Frappe server is accessible',
          'Ensure the base URL is correct',
          'Check if the server requires VPN access',
        ]);
      }
    } catch (e) {
      issues.add('Network connectivity test failed: $e');
      suggestions.add('Check your network connection and try again');
    }

    if (issues.isEmpty) {
      return ValidationResult.success(
        context: {
          'connectivityTest': 'passed',
          'testedAt': DateTime.now().toIso8601String(),
        },
      );
    }

    return ValidationResult.failure(
      issues: issues,
      suggestions: suggestions,
      context: {
        'connectivityTest': 'failed',
        'testedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Validates a URL format
  static List<String> _validateUrl(String url) {
    final issues = <String>[];

    if (url.isEmpty) {
      issues.add('URL cannot be empty');
      return issues;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      issues.add('Invalid URL format');
      return issues;
    }

    if (!uri.hasScheme || !['http', 'https'].contains(uri.scheme.toLowerCase())) {
      issues.add('URL must use http or https scheme');
    }

    if (!uri.hasAuthority) {
      issues.add('URL must include a host');
    }

    return issues;
  }

  /// Validates Android-specific configuration
  static List<String> _validateAndroidConfig(
    String redirectScheme,
    Map<String, dynamic> config,
  ) {
    final issues = <String>[];

    // Check for common Android issues
    if (redirectScheme.contains('_')) {
      issues.add('Android schemes should avoid underscores, use hyphens instead');
    }

    if (redirectScheme.startsWith('android-app')) {
      issues.add('Avoid using android-app prefix for custom schemes');
    }

    // Additional Android-specific validations would go here
    // e.g., checking AndroidManifest.xml configuration

    return issues;
  }

  /// Validates iOS-specific configuration
  static List<String> _validateIOSConfig(
    String redirectScheme,
    Map<String, dynamic> config,
  ) {
    final issues = <String>[];

    // Check for common iOS issues
    if (redirectScheme.length < 3) {
      issues.add('iOS URL schemes should be at least 3 characters long');
    }

    if (redirectScheme.contains('_')) {
      issues.add('iOS schemes should avoid underscores, use hyphens instead');
    }

    // Additional iOS-specific validations would go here
    // e.g., checking Info.plist configuration

    return issues;
  }

  /// Validates web-specific configuration
  static List<String> _validateWebConfig(
    String redirectScheme,
    Map<String, dynamic> config,
  ) {
    final issues = <String>[];

    // For web, we typically use http/https URLs instead of custom schemes
    if (!['http', 'https'].contains(redirectScheme)) {
      issues.add('Web platform typically uses http/https redirect URLs');
    }

    return issues;
  }
}
