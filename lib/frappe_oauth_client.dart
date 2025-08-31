import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'exceptions/frappe_auth_exception.dart';
import 'models/auth_result.dart';
import 'models/oauth_config.dart';
import 'models/token_response.dart';
import 'models/user_info.dart';
import 'services/network_service.dart';

/// Main client for Frappe OAuth2 authentication
///
/// Provides a complete OAuth2 authentication flow including:
/// - Authorization code flow with PKCE
/// - Token exchange and refresh
/// - User information retrieval
/// - Session management
class FrappeOAuthClient {
  final OAuthConfig config;
  final NetworkService _networkService;

  /// Current authentication state
  TokenResponse? _currentTokens;
  UserInfo? _currentUser;

  FrappeOAuthClient({required this.config, NetworkService? networkService})
    : _networkService = networkService ?? NetworkService(config: config) {
    // Validate configuration on initialization
    final issues = config.validate();
    if (issues.isNotEmpty) {
      throw FrappeConfigurationException(
        'Invalid OAuth configuration: ${issues.join(', ')}',
        code: 'invalid_config',
        context: {'issues': issues},
      );
    }
  }

  /// Initiates the OAuth2 login flow
  ///
  /// Returns an [AuthResult] containing either successful authentication
  /// data or error information.
  Future<AuthResult> login() async {
    try {
      // Generate PKCE parameters
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // Build authorization URL
      final authUrl = _buildAuthorizationUrl(codeChallenge);

      // Open web authentication
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: config.redirectScheme,
      );

      // Extract authorization code from callback
      final authCode = _extractAuthorizationCode(result);

      // Exchange authorization code for tokens
      final tokens = await _exchangeCodeForTokens(authCode, codeVerifier);

      // Fetch user information
      final userInfo = await _fetchUserInfo(tokens.accessToken);

      // Store current session
      _currentTokens = tokens;
      _currentUser = userInfo;

      return AuthResult.success(
        userInfo: userInfo,
        tokens: tokens,
        metadata: {
          'loginTime': DateTime.now().toIso8601String(),
          'method': 'oauth2_authorization_code',
        },
      );
    } on FrappeUserCancelledException catch (e) {
      return AuthResult.cancelled(
        message: e.message,
        metadata: {'cancelledAt': DateTime.now().toIso8601String()},
      );
    } on FrappeAuthException catch (e) {
      return AuthResult.failure(
        error: e,
        metadata: {'failedAt': DateTime.now().toIso8601String()},
      );
    } catch (e, stackTrace) {
      final authException = FrappeNetworkException(
        'Unexpected error during login: $e',
        code: 'unexpected_error',
        originalError: e,
        originalStackTrace: stackTrace,
      );

      return AuthResult.failure(
        error: authException,
        metadata: {'failedAt': DateTime.now().toIso8601String()},
      );
    }
  }

  /// Logs out the current user
  ///
  /// Clears all stored authentication data and tokens.
  Future<void> logout() async {
    _currentTokens = null;
    _currentUser = null;
    // Storage clearing is handled by the simplified client
  }

  /// Checks if the user is currently authenticated
  ///
  /// Returns true if there are valid, non-expired tokens.
  bool isAuthenticated() {
    return _currentTokens != null && _currentTokens!.isValid;
  }

  /// Gets the current user information
  ///
  /// Returns null if not authenticated.
  UserInfo? getCurrentUser() {
    return isAuthenticated() ? _currentUser : null;
  }

  /// Gets the current access token
  ///
  /// Returns null if not authenticated or token is expired.
  String? getAccessToken() {
    return isAuthenticated() ? _currentTokens!.accessToken : null;
  }

  /// Refreshes the current access token using the refresh token
  ///
  /// Returns the new token response or throws an exception if refresh fails.
  Future<TokenResponse> refreshToken() async {
    if (_currentTokens == null) {
      throw FrappeTokenException(
        'No tokens available to refresh',
        code: 'no_tokens',
      );
    }

    try {
      final newTokens = await _refreshTokens(_currentTokens!.refreshToken);
      _currentTokens = newTokens;
      return newTokens;
    } catch (e) {
      // If refresh fails, clear current tokens
      _currentTokens = null;
      _currentUser = null;
      rethrow;
    }
  }

  /// Generates a cryptographically secure code verifier for PKCE
  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Generates a code challenge from the code verifier using SHA256
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Builds the OAuth2 authorization URL with all required parameters
  String _buildAuthorizationUrl(String codeChallenge) {
    final params = {
      'client_id': config.clientId,
      'response_type': 'code',
      'redirect_uri': config.redirectUri,
      'scope': config.scopeString,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': _generateState(),
      ...config.additionalAuthParams,
    };

    final uri = Uri.parse(config.authorizationEndpoint);
    return uri.replace(queryParameters: params).toString();
  }

  /// Generates a random state parameter for CSRF protection
  String _generateState() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Extracts the authorization code from the callback URL
  String _extractAuthorizationCode(String callbackUrl) {
    final uri = Uri.parse(callbackUrl);

    // Check for error parameters
    if (uri.queryParameters.containsKey('error')) {
      final error = uri.queryParameters['error']!;
      final errorDescription = uri.queryParameters['error_description'];

      if (error == 'access_denied') {
        throw FrappeUserCancelledException(
          errorDescription ?? 'User denied access',
        );
      }

      throw FrappeNetworkException(
        errorDescription ?? 'Authorization failed: $error',
        code: error,
      );
    }

    // Extract authorization code
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw FrappeNetworkException(
        'No authorization code received',
        code: 'missing_auth_code',
      );
    }

    return code;
  }

  /// Exchanges authorization code for access and refresh tokens
  Future<TokenResponse> _exchangeCodeForTokens(
    String authCode,
    String codeVerifier,
  ) async {
    try {
      final response = await _networkService.post(
        config.tokenEndpoint,
        formData: {
          'grant_type': 'authorization_code',
          'code': authCode,
          'redirect_uri': config.redirectUri,
          'client_id': config.clientId,
          'code_verifier': codeVerifier,
        },
      );

      return TokenResponse.fromJson(response);
    } on FrappeNetworkException catch (e) {
      throw FrappeTokenException(
        'Token exchange failed: ${e.message}',
        code: 'token_exchange_failed',
        originalError: e,
      );
    }
  }

  /// Refreshes tokens using the refresh token
  Future<TokenResponse> _refreshTokens(String refreshToken) async {
    try {
      final response = await _networkService.post(
        config.tokenEndpoint,
        formData: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': config.clientId,
        },
      );

      return TokenResponse.fromJson(response);
    } on FrappeNetworkException catch (e) {
      throw FrappeTokenException(
        'Token refresh failed: ${e.message}',
        code: 'refresh_failed',
        originalError: e,
      );
    }
  }

  /// Fetches user information using the access token
  Future<UserInfo> _fetchUserInfo(String accessToken) async {
    try {
      final response = await _networkService.get(
        config.userInfoEndpoint,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      return UserInfo.fromJson(response);
    } on FrappeNetworkException catch (e) {
      throw FrappeNetworkException(
        'Failed to fetch user info: ${e.message}',
        code: 'user_info_failed',
        originalError: e,
      );
    }
  }

  /// Disposes of resources
  void dispose() {
    _networkService.dispose();
  }
}
