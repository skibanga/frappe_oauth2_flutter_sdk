import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../exceptions/frappe_auth_exception.dart';
import '../models/oauth_config.dart';

/// Simple web authentication service that wraps flutter_web_auth_2
///
/// Provides a clean interface for OAuth2 web authentication flows
/// without exposing platform-specific complexities.
class WebAuthService {
  final OAuthConfig config;

  const WebAuthService({required this.config});

  /// Performs OAuth2 authentication using the system browser
  ///
  /// Returns the authorization code from the callback URL.
  /// Throws [FrappeAuthException] for various error scenarios.
  Future<String> authenticate({
    required String authorizationUrl,
    required String callbackUrlScheme,
  }) async {
    try {
      // Perform web authentication
      final result = await FlutterWebAuth2.authenticate(
        url: authorizationUrl,
        callbackUrlScheme: callbackUrlScheme,
      );

      // Extract authorization code from callback URL
      final code = _extractAuthorizationCode(result);
      if (code == null) {
        throw FrappeNetworkException(
          'No authorization code found in callback URL',
        );
      }

      return code;
    } catch (e) {
      if (e is FrappeAuthException) {
        rethrow;
      }

      // Handle flutter_web_auth_2 specific errors
      if (e.toString().contains('User cancelled')) {
        throw FrappeUserCancelledException(
          'User cancelled the authentication process',
        );
      }

      if (e.toString().contains('RESULT_CANCELED')) {
        throw FrappeUserCancelledException('Authentication was cancelled');
      }

      // Generic authentication error
      throw FrappeNetworkException(
        'Authentication failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Checks if web authentication is available on the current platform
  static Future<bool> isAvailable() async {
    try {
      // flutter_web_auth_2 is available on all supported platforms
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extracts the authorization code from the OAuth callback URL
  String? _extractAuthorizationCode(String callbackUrl) {
    try {
      final uri = Uri.parse(callbackUrl);

      // Check for authorization code in query parameters
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        return code;
      }

      // Check for error in callback
      final error = uri.queryParameters['error'];
      if (error != null) {
        final errorDescription =
            uri.queryParameters['error_description'] ?? error;
        throw FrappeNetworkException('OAuth error: $errorDescription');
      }

      return null;
    } catch (e) {
      if (e is FrappeAuthException) {
        rethrow;
      }

      throw FrappeNetworkException(
        'Failed to parse callback URL: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Validates the callback URL scheme matches the configuration
  bool validateCallbackScheme(String callbackUrl) {
    try {
      final uri = Uri.parse(callbackUrl);
      return uri.scheme.toLowerCase() == config.redirectScheme.toLowerCase();
    } catch (e) {
      return false;
    }
  }

  /// Builds the redirect URI for OAuth2 flow
  String buildRedirectUri() {
    return '${config.redirectScheme}://oauth2redirect';
  }
}

/// Exception thrown when user cancels the authentication process
class FrappeUserCancelledException extends FrappeAuthException {
  FrappeUserCancelledException(super.message) : super(code: 'USER_CANCELLED');
}
