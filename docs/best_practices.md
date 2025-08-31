# Best Practices - Frappe OAuth2 Flutter SDK

## Overview

This guide covers best practices for implementing secure, maintainable, and user-friendly OAuth2 authentication in your Flutter app.

## Architecture Patterns

### 1. Service Layer Pattern

Create a dedicated authentication service:

```dart
class AuthService {
  static FrappeOAuthClient? _client;
  static final _authStateController = StreamController<AuthState>.broadcast();
  
  static Stream<AuthState> get authStateStream => _authStateController.stream;
  
  static Future<FrappeOAuthClient> _getClient() async {
    _client ??= await FrappeOAuthClient.create(config: AppConfig.oauthConfig);
    return _client!;
  }
  
  static Future<AuthResult> login() async {
    final client = await _getClient();
    final result = await client.login();
    
    if (result.isSuccess) {
      _authStateController.add(AuthState.authenticated(result.userInfo!));
    }
    
    return result;
  }
  
  static Future<void> logout() async {
    final client = await _getClient();
    await client.logout();
    _authStateController.add(AuthState.unauthenticated());
  }
  
  static Future<bool> isAuthenticated() async {
    final client = await _getClient();
    return await client.isAuthenticated();
  }
}

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserInfo? user;
  
  const AuthState._(this.status, this.user);
  
  factory AuthState.authenticated(UserInfo user) => 
    AuthState._(AuthStatus.authenticated, user);
  
  factory AuthState.unauthenticated() => 
    AuthState._(AuthStatus.unauthenticated, null);
  
  factory AuthState.loading() => 
    AuthState._(AuthStatus.loading, null);
}
```

### 2. Repository Pattern for API Calls

```dart
abstract class ApiRepository {
  Future<T> makeAuthenticatedRequest<T>(
    Future<T> Function(String token) request,
  );
}

class FrappeApiRepository implements ApiRepository {
  @override
  Future<T> makeAuthenticatedRequest<T>(
    Future<T> Function(String token) request,
  ) async {
    final client = await AuthService._getClient();
    
    if (!await client.isAuthenticated()) {
      throw UnauthenticatedException();
    }
    
    var token = await client.getAccessToken();
    
    try {
      return await request(token!);
    } on UnauthorizedException {
      // Try to refresh token
      final newTokens = await client.refreshToken();
      if (newTokens != null) {
        return await request(newTokens.accessToken);
      } else {
        // Refresh failed, logout user
        await AuthService.logout();
        throw UnauthenticatedException();
      }
    }
  }
}
```

### 3. State Management Integration

#### With Provider

```dart
class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.loading();
  AuthState get state => _state;
  
  AuthProvider() {
    _init();
  }
  
  Future<void> _init() async {
    final isAuth = await AuthService.isAuthenticated();
    if (isAuth) {
      final client = await AuthService._getClient();
      final user = await client.getCurrentUser();
      _state = AuthState.authenticated(user!);
    } else {
      _state = AuthState.unauthenticated();
    }
    notifyListeners();
  }
  
  Future<void> login() async {
    _state = AuthState.loading();
    notifyListeners();
    
    final result = await AuthService.login();
    if (result.isSuccess) {
      _state = AuthState.authenticated(result.userInfo!);
    } else {
      _state = AuthState.unauthenticated();
    }
    notifyListeners();
  }
  
  Future<void> logout() async {
    await AuthService.logout();
    _state = AuthState.unauthenticated();
    notifyListeners();
  }
}
```

#### With Bloc

```dart
abstract class AuthEvent {}
class AuthLoginRequested extends AuthEvent {}
class AuthLogoutRequested extends AuthEvent {}
class AuthStatusChecked extends AuthEvent {}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthState.loading()) {
    on<AuthStatusChecked>(_onAuthStatusChecked);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    
    add(AuthStatusChecked());
  }
  
  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    final isAuth = await AuthService.isAuthenticated();
    if (isAuth) {
      final client = await AuthService._getClient();
      final user = await client.getCurrentUser();
      emit(AuthState.authenticated(user!));
    } else {
      emit(AuthState.unauthenticated());
    }
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());
    
    final result = await AuthService.login();
    if (result.isSuccess) {
      emit(AuthState.authenticated(result.userInfo!));
    } else {
      emit(AuthState.unauthenticated());
    }
  }
  
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await AuthService.logout();
    emit(AuthState.unauthenticated());
  }
}
```

## Security Best Practices

### 1. Configuration Management

```dart
class AppConfig {
  // Use environment variables for sensitive data
  static const String baseUrl = String.fromEnvironment(
    'FRAPPE_BASE_URL',
    defaultValue: 'https://demo.frappe.cloud',
  );
  
  static const String clientId = String.fromEnvironment('FRAPPE_CLIENT_ID');
  
  static const bool isProduction = bool.fromEnvironment('PRODUCTION');
  
  static OAuthConfig get oauthConfig => OAuthConfig(
    baseUrl: baseUrl,
    clientId: clientId,
    redirectScheme: _getRedirectScheme(),
    scopes: ['openid', 'profile', 'email'],
    enableLogging: !isProduction,
  );
  
  static String _getRedirectScheme() {
    if (isProduction) {
      return 'myapp';
    } else {
      return 'myapp-dev';
    }
  }
}
```

### 2. Token Security

```dart
class SecureTokenManager {
  static const String _tokenKey = 'secure_tokens';
  
  // Consider using flutter_secure_storage for enhanced security
  static Future<void> storeTokens(TokenResponse tokens) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenData = {
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
      'expires_at': tokens.issuedAt.add(
        Duration(seconds: tokens.expiresIn ?? 3600)
      ).millisecondsSinceEpoch,
    };
    
    await prefs.setString(_tokenKey, jsonEncode(tokenData));
  }
  
  static Future<bool> areTokensValid() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenData = prefs.getString(_tokenKey);
    
    if (tokenData == null) return false;
    
    final data = jsonDecode(tokenData);
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(data['expires_at']);
    
    return DateTime.now().isBefore(expiresAt.subtract(Duration(minutes: 5)));
  }
}
```

### 3. Deep Link Validation

```dart
class DeepLinkHandler {
  static bool isValidAuthCallback(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Validate scheme
      if (uri.scheme != AppConfig.oauthConfig.redirectScheme) {
        return false;
      }
      
      // Validate host
      if (uri.host != 'oauth2redirect') {
        return false;
      }
      
      // Check for required parameters
      return uri.queryParameters.containsKey('code') ||
             uri.queryParameters.containsKey('error');
    } catch (e) {
      return false;
    }
  }
  
  static void handleDeepLink(String url) {
    if (!isValidAuthCallback(url)) {
      // Log security incident
      print('Invalid deep link received: $url');
      return;
    }
    
    // Process valid callback
    // This is handled automatically by the SDK
  }
}
```

## Error Handling Patterns

### 1. Comprehensive Error Handling

```dart
class AuthErrorHandler {
  static void handleAuthError(FrappeAuthException error) {
    switch (error.runtimeType) {
      case FrappeNetworkException:
        _handleNetworkError(error as FrappeNetworkException);
        break;
      case FrappeUserCancelledException:
        _handleUserCancellation(error as FrappeUserCancelledException);
        break;
      case FrappeConfigurationException:
        _handleConfigurationError(error as FrappeConfigurationException);
        break;
      default:
        _handleGenericError(error);
    }
  }
  
  static void _handleNetworkError(FrappeNetworkException error) {
    if (error.statusCode == 401) {
      // Token expired, trigger re-authentication
      AuthService.logout();
    } else if (error.statusCode == 403) {
      // Insufficient permissions
      _showError('Access denied. Please contact administrator.');
    } else if (error.statusCode >= 500) {
      // Server error
      _showError('Server error. Please try again later.');
    } else {
      // Other network errors
      _showError('Network error. Please check your connection.');
    }
  }
  
  static void _handleUserCancellation(FrappeUserCancelledException error) {
    // User cancelled - usually no action needed
    print('User cancelled authentication');
  }
  
  static void _handleConfigurationError(FrappeConfigurationException error) {
    // Configuration error - log for debugging
    print('Configuration error: ${error.message}');
    _showError('App configuration error. Please contact support.');
  }
  
  static void _handleGenericError(FrappeAuthException error) {
    print('Authentication error: ${error.message}');
    _showError('Authentication failed. Please try again.');
  }
  
  static void _showError(String message) {
    // Show user-friendly error message
    // Implementation depends on your UI framework
  }
}
```

### 2. Retry Logic

```dart
class RetryableAuthService {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = maxRetries,
  }) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxAttempts) {
          rethrow;
        }
        
        if (e is FrappeNetworkException && e.statusCode >= 500) {
          // Retry server errors
          await Future.delayed(retryDelay * attempts);
        } else {
          // Don't retry client errors
          rethrow;
        }
      }
    }
    
    throw Exception('Max retry attempts exceeded');
  }
}
```

## Performance Optimization

### 1. Token Caching

```dart
class TokenCache {
  static TokenResponse? _cachedTokens;
  static DateTime? _cacheTime;
  static const Duration cacheTimeout = Duration(minutes: 5);
  
  static Future<String?> getAccessToken() async {
    // Check cache first
    if (_cachedTokens != null && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!) < cacheTimeout) {
      return _cachedTokens!.accessToken;
    }
    
    // Fetch from storage/client
    final client = await AuthService._getClient();
    final token = await client.getAccessToken();
    
    if (token != null) {
      _cachedTokens = await client.getCurrentTokens();
      _cacheTime = DateTime.now();
    }
    
    return token;
  }
  
  static void clearCache() {
    _cachedTokens = null;
    _cacheTime = null;
  }
}
```

### 2. Lazy Initialization

```dart
class LazyAuthService {
  static FrappeOAuthClient? _client;
  static Future<FrappeOAuthClient>? _clientFuture;
  
  static Future<FrappeOAuthClient> getClient() {
    _clientFuture ??= _initializeClient();
    return _clientFuture!;
  }
  
  static Future<FrappeOAuthClient> _initializeClient() async {
    _client = await FrappeOAuthClient.create(config: AppConfig.oauthConfig);
    return _client!;
  }
  
  static void dispose() {
    _client?.dispose();
    _client = null;
    _clientFuture = null;
  }
}
```

## User Experience Best Practices

### 1. Loading States

```dart
class AuthLoadingWidget extends StatelessWidget {
  final String message;
  
  const AuthLoadingWidget({
    Key? key,
    this.message = 'Authenticating...',
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}
```

### 2. Graceful Error Recovery

```dart
class AuthErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  
  const AuthErrorWidget({
    Key? key,
    required this.error,
    required this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 3. Biometric Authentication Integration

```dart
class BiometricAuthService {
  static Future<bool> isBiometricAvailable() async {
    final localAuth = LocalAuthentication();
    return await localAuth.canCheckBiometrics;
  }
  
  static Future<bool> authenticateWithBiometrics() async {
    final localAuth = LocalAuthentication();
    
    try {
      return await localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> enableBiometricAuth() async {
    if (await isBiometricAvailable()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_auth_enabled', true);
    }
  }
  
  static Future<bool> isBiometricAuthEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_auth_enabled') ?? false;
  }
}
```

## Testing Best Practices

### 1. Mock Authentication Service

```dart
class MockAuthService implements AuthService {
  bool _isAuthenticated = false;
  UserInfo? _currentUser;
  
  @override
  Future<AuthResult> login() async {
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    
    _isAuthenticated = true;
    _currentUser = UserInfo(
      sub: 'test_user',
      email: 'test@example.com',
      fullName: 'Test User',
    );
    
    return AuthResult.success(
      userInfo: _currentUser!,
      tokens: TokenResponse(
        accessToken: 'mock_access_token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      ),
    );
  }
  
  @override
  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = null;
  }
  
  @override
  Future<bool> isAuthenticated() async {
    return _isAuthenticated;
  }
  
  @override
  Future<UserInfo?> getCurrentUser() async {
    return _currentUser;
  }
}
```

### 2. Integration Tests

```dart
void main() {
  group('Authentication Flow Integration Tests', () {
    testWidgets('complete login flow', (WidgetTester tester) async {
      // Setup mock service
      final mockAuthService = MockAuthService();
      
      await tester.pumpWidget(
        MaterialApp(
          home: AuthWrapper(authService: mockAuthService),
        ),
      );
      
      // Verify login screen is shown
      expect(find.text('Login'), findsOneWidget);
      
      // Tap login button
      await tester.tap(find.text('Login with Frappe'));
      await tester.pumpAndSettle();
      
      // Verify home screen is shown after login
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
```

## Monitoring and Analytics

### 1. Authentication Analytics

```dart
class AuthAnalytics {
  static void trackLoginAttempt() {
    // Track login attempts
    FirebaseAnalytics.instance.logEvent(name: 'login_attempt');
  }
  
  static void trackLoginSuccess() {
    FirebaseAnalytics.instance.logEvent(name: 'login_success');
  }
  
  static void trackLoginFailure(String reason) {
    FirebaseAnalytics.instance.logEvent(
      name: 'login_failure',
      parameters: {'reason': reason},
    );
  }
  
  static void trackTokenRefresh() {
    FirebaseAnalytics.instance.logEvent(name: 'token_refresh');
  }
}
```

### 2. Error Reporting

```dart
class AuthErrorReporting {
  static void reportError(
    FrappeAuthException error, {
    Map<String, dynamic>? context,
  }) {
    FirebaseCrashlytics.instance.recordError(
      error,
      error.stackTrace,
      context: context,
    );
  }
  
  static void reportConfigurationIssue(String issue) {
    FirebaseCrashlytics.instance.log('Configuration issue: $issue');
  }
}
```

These best practices ensure your OAuth2 implementation is secure, maintainable, performant, and provides an excellent user experience.
