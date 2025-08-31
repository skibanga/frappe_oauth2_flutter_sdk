import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exceptions/frappe_auth_exception.dart';
import 'models/auth_result.dart';
import 'models/oauth_config.dart';
import 'models/token_response.dart';
import 'models/user_info.dart';
import 'services/network_service.dart';
import 'services/web_auth_service.dart';
import 'utils/url_builder.dart';

/// Simplified main client for Frappe OAuth2 authentication
///
/// Provides a clean, headless OAuth2 authentication flow:
/// - Authorization code flow with PKCE
/// - Token exchange and refresh
/// - User information retrieval
/// - SharedPreferences storage
class FrappeOAuthClient {
  final OAuthConfig config;
  final NetworkService _networkService;
  final WebAuthService _webAuthService;
  final UrlBuilder _urlBuilder;

  // Storage keys
  static const String _tokenKey = 'frappe_oauth_tokens';
  static const String _userKey = 'frappe_oauth_user';

  /// Current authentication state
  TokenResponse? _currentTokens;
  UserInfo? _currentUser;

  FrappeOAuthClient._({
    required this.config,
    required NetworkService networkService,
    required WebAuthService webAuthService,
    required UrlBuilder urlBuilder,
  }) : _networkService = networkService,
       _webAuthService = webAuthService,
       _urlBuilder = urlBuilder;

  /// Factory constructor to create a properly initialized client
  static Future<FrappeOAuthClient> create({required OAuthConfig config}) async {
    // Validate configuration
    _validateConfig(config);

    final networkService = NetworkService(config: config);
    final webAuthService = WebAuthService(config: config);
    final urlBuilder = UrlBuilder(config: config);

    final client = FrappeOAuthClient._(
      config: config,
      networkService: networkService,
      webAuthService: webAuthService,
      urlBuilder: urlBuilder,
    );

    // Load existing tokens if available
    await client._loadStoredTokens();

    return client;
  }

  /// Validates the OAuth configuration
  static void _validateConfig(OAuthConfig config) {
    final errors = <String>[];

    if (config.baseUrl.isEmpty) {
      errors.add('Base URL cannot be empty');
    }
    if (config.clientId.isEmpty) {
      errors.add('Client ID cannot be empty');
    }
    if (config.redirectScheme.isEmpty) {
      errors.add('Redirect scheme cannot be empty');
    }
    if (config.scopes.isEmpty) {
      errors.add('At least one scope must be specified');
    }

    if (errors.isNotEmpty) {
      throw FrappeConfigurationException(
        'Invalid OAuth configuration: ${errors.join(', ')}',
      );
    }
  }

  /// Initiates the OAuth2 login flow
  Future<AuthResult> login() async {
    try {
      // Generate PKCE parameters
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateState();

      // Build authorization URL
      final authUrl = UrlBuilder.buildAuthorizationUrlStatic(
        baseUrl: config.baseUrl,
        clientId: config.clientId,
        redirectUri: '${config.redirectScheme}://oauth2redirect',
        scope: config.scopes.join(' '),
        codeChallenge: codeChallenge,
        state: state,
      );

      // Perform web authentication
      final authCode = await _webAuthService.authenticate(
        authorizationUrl: authUrl,
        callbackUrlScheme: config.redirectScheme,
      );

      // Exchange code for tokens
      final tokens = await _exchangeCodeForTokens(authCode, codeVerifier);

      // Get user info
      final userInfo = await _getUserInfo(tokens.accessToken);

      // Store tokens and user info
      await _storeTokens(tokens);
      await _storeUserInfo(userInfo);

      _currentTokens = tokens;
      _currentUser = userInfo;

      return AuthResult.success(userInfo: userInfo, tokens: tokens);
    } on FrappeUserCancelledException catch (e) {
      return AuthResult.cancelled(message: e.message);
    } catch (e) {
      if (e is FrappeAuthException) {
        return AuthResult.failure(error: e);
      }

      final authException = FrappeNetworkException(
        'Login failed: ${e.toString()}',
        originalError: e,
      );
      return AuthResult.failure(error: authException);
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    try {
      // Revoke tokens if available
      if (_currentTokens?.accessToken != null) {
        await _revokeToken(_currentTokens!.accessToken);
      }
    } catch (e) {
      // Continue with logout even if revocation fails
      // In production, you might want to use a proper logging framework
      if (config.enableLogging) {
        // Token revocation failed, but continue with logout
      }
    }

    // Clear stored data
    await _clearStoredData();

    _currentTokens = null;
    _currentUser = null;
  }

  /// Checks if user is currently authenticated
  Future<bool> isAuthenticated() async {
    if (_currentTokens == null) {
      await _loadStoredTokens();
    }

    return _currentTokens != null && !_currentTokens!.isExpired;
  }

  /// Gets the current user info
  Future<UserInfo?> getCurrentUser() async {
    if (_currentUser == null) {
      await _loadStoredUserInfo();
    }
    return _currentUser;
  }

  /// Gets the current access token
  Future<String?> getAccessToken() async {
    if (_currentTokens == null) {
      await _loadStoredTokens();
    }

    if (_currentTokens != null && !_currentTokens!.isExpired) {
      return _currentTokens!.accessToken;
    }

    return null;
  }

  /// Refreshes the access token
  Future<TokenResponse?> refreshToken() async {
    if (_currentTokens?.refreshToken == null) {
      return null;
    }

    try {
      final newTokens = await _refreshAccessToken(_currentTokens!.refreshToken);
      await _storeTokens(newTokens);
      _currentTokens = newTokens;
      return newTokens;
    } catch (e) {
      // If refresh fails, clear tokens
      await logout();
      return null;
    }
  }

  /// Disposes of the client and cleans up resources
  Future<void> dispose() async {
    // Nothing specific to dispose in this simple implementation
  }

  // Private helper methods

  Future<TokenResponse> _exchangeCodeForTokens(
    String code,
    String codeVerifier,
  ) async {
    final tokenUrl = _urlBuilder.buildTokenUrl();
    final redirectUri = '${config.redirectScheme}://oauth2redirect';

    final response = await _networkService.post(
      tokenUrl,
      body: {
        'grant_type': 'authorization_code',
        'client_id': config.clientId,
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier,
      },
    );

    return TokenResponse.fromJson(response);
  }

  Future<UserInfo> _getUserInfo(String accessToken) async {
    final userInfoUrl = _urlBuilder.buildUserInfoUrl();

    final response = await _networkService.get(
      userInfoUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    return UserInfo.fromJson(response);
  }

  Future<TokenResponse> _refreshAccessToken(String refreshToken) async {
    final tokenUrl = _urlBuilder.buildTokenUrl();

    final response = await _networkService.post(
      tokenUrl,
      body: {
        'grant_type': 'refresh_token',
        'client_id': config.clientId,
        'refresh_token': refreshToken,
      },
    );

    return TokenResponse.fromJson(response);
  }

  Future<void> _revokeToken(String token) async {
    final revokeUrl =
        '${config.baseUrl}/api/method/frappe.integrations.oauth2.revoke_token';

    await _networkService.post(
      revokeUrl,
      body: {'token': token, 'client_id': config.clientId},
    );
  }

  Future<void> _storeTokens(TokenResponse tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, jsonEncode(tokens.toJson()));
  }

  Future<void> _storeUserInfo(UserInfo userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userInfo.toJson()));
  }

  Future<void> _loadStoredTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenData = prefs.getString(_tokenKey);

    if (tokenData != null) {
      try {
        final tokenJson = jsonDecode(tokenData) as Map<String, dynamic>;
        _currentTokens = TokenResponse.fromJson(tokenJson);
      } catch (e) {
        // Clear invalid token data
        await prefs.remove(_tokenKey);
      }
    }
  }

  Future<void> _loadStoredUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);

    if (userData != null) {
      try {
        final userJson = jsonDecode(userData) as Map<String, dynamic>;
        _currentUser = UserInfo.fromJson(userJson);
      } catch (e) {
        // Clear invalid user data
        await prefs.remove(_userKey);
      }
    }
  }

  Future<void> _clearStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  String _generateCodeVerifier() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    return List.generate(
      128,
      (i) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _generateState() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(32, (i) => chars[random.nextInt(chars.length)]).join();
  }
}

// FrappeConfigurationException is imported from exceptions/frappe_auth_exception.dart
