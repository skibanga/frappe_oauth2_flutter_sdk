# Frappe OAuth2 Flutter SDK - API Reference

## Overview

The Frappe OAuth2 Flutter SDK provides a clean, headless OAuth2 authentication solution for Flutter applications connecting to Frappe servers. This SDK handles the complete OAuth2 authorization code flow with PKCE support.

## Core Classes

### FrappeOAuthClient

The main client class for OAuth2 authentication.

#### Factory Constructor

```dart
static Future<FrappeOAuthClient> create({
  required OAuthConfig config,
})
```

Creates and initializes a new OAuth client with the provided configuration.

**Parameters:**
- `config` - OAuth2 configuration (see [OAuthConfig](#oauthconfig))

**Returns:** `Future<FrappeOAuthClient>` - Initialized client instance

**Throws:** `FrappeConfigurationException` if configuration is invalid

**Example:**
```dart
final config = OAuthConfig(
  baseUrl: 'https://your-frappe-server.com',
  clientId: 'your-client-id',
  redirectScheme: 'yourapp',
  scopes: ['openid', 'profile', 'email'],
);

final client = await FrappeOAuthClient.create(config: config);
```

#### Authentication Methods

##### login()

```dart
Future<AuthResult> login()
```

Initiates the OAuth2 login flow using the system browser.

**Returns:** `Future<AuthResult>` - Result containing user info and tokens on success

**Example:**
```dart
final result = await client.login();
if (result.isSuccess) {
  print('Logged in as: ${result.userInfo?.email}');
  // Use result.tokens for API calls
} else if (result.isCancelled) {
  print('User cancelled login');
} else {
  print('Login failed: ${result.error?.message}');
}
```

##### logout()

```dart
Future<void> logout()
```

Logs out the current user and clears all stored authentication data.

**Example:**
```dart
await client.logout();
print('User logged out successfully');
```

#### State Management Methods

##### isAuthenticated()

```dart
Future<bool> isAuthenticated()
```

Checks if the user is currently authenticated with valid tokens.

**Returns:** `Future<bool>` - True if authenticated with valid tokens

**Example:**
```dart
if (await client.isAuthenticated()) {
  // User is logged in
  final token = await client.getAccessToken();
  // Make authenticated API calls
}
```

##### getCurrentUser()

```dart
Future<UserInfo?> getCurrentUser()
```

Gets the current authenticated user's information.

**Returns:** `Future<UserInfo?>` - User information or null if not authenticated

**Example:**
```dart
final user = await client.getCurrentUser();
if (user != null) {
  print('Current user: ${user.email}');
  print('Full name: ${user.fullName}');
}
```

##### getAccessToken()

```dart
Future<String?> getAccessToken()
```

Gets the current access token for API calls.

**Returns:** `Future<String?>` - Access token or null if not authenticated

**Example:**
```dart
final token = await client.getAccessToken();
if (token != null) {
  // Use token for API calls
  final response = await http.get(
    Uri.parse('https://your-server.com/api/resource'),
    headers: {'Authorization': 'Bearer $token'},
  );
}
```

#### Token Management

##### refreshToken()

```dart
Future<TokenResponse?> refreshToken()
```

Refreshes the access token using the stored refresh token.

**Returns:** `Future<TokenResponse?>` - New tokens or null if refresh failed

**Example:**
```dart
final newTokens = await client.refreshToken();
if (newTokens != null) {
  print('Token refreshed successfully');
} else {
  print('Token refresh failed, user needs to login again');
}
```

##### dispose()

```dart
Future<void> dispose()
```

Disposes of the client and cleans up resources.

**Example:**
```dart
await client.dispose();
```

## Configuration Models

### OAuthConfig

Configuration class for OAuth2 settings.

```dart
class OAuthConfig {
  final String baseUrl;
  final String clientId;
  final String redirectScheme;
  final List<String> scopes;
  final bool enableLogging;
  
  const OAuthConfig({
    required this.baseUrl,
    required this.clientId,
    required this.redirectScheme,
    this.scopes = const ['openid', 'profile', 'email'],
    this.enableLogging = false,
  });
}
```

**Properties:**
- `baseUrl` - Your Frappe server URL (e.g., 'https://your-server.com')
- `clientId` - OAuth2 client ID from your Frappe server
- `redirectScheme` - Custom URL scheme for your app (e.g., 'yourapp')
- `scopes` - OAuth2 scopes to request (default: ['openid', 'profile', 'email'])
- `enableLogging` - Enable debug logging (default: false)

**Example:**
```dart
final config = OAuthConfig(
  baseUrl: 'https://erp.mycompany.com',
  clientId: 'mobile_app_client',
  redirectScheme: 'mycompanyapp',
  scopes: ['openid', 'profile', 'email', 'offline_access'],
  enableLogging: true, // Enable for debugging
);
```

## Response Models

### AuthResult

Result of an authentication operation.

```dart
class AuthResult {
  final bool success;
  final UserInfo? userInfo;
  final TokenResponse? tokens;
  final FrappeAuthException? error;
  final bool cancelled;
  
  // Helper getters
  bool get isSuccess => success;
  bool get isFailure => !success && !cancelled;
  bool get isCancelled => cancelled;
}
```

**Properties:**
- `success` - Whether authentication succeeded
- `userInfo` - User information (if successful)
- `tokens` - OAuth2 tokens (if successful)
- `error` - Error details (if failed)
- `cancelled` - Whether user cancelled the flow

### UserInfo

User information from the OAuth2 provider.

```dart
class UserInfo {
  final String sub;
  final String email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? picture;
  
  // Helper getters
  String get displayName => fullName ?? email;
}
```

### TokenResponse

OAuth2 token information.

```dart
class TokenResponse {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int? expiresIn;
  final DateTime issuedAt;
  final List<String> scope;
  
  // Helper methods
  bool get isExpired;
  bool get isExpiringSoon;
  Duration get timeUntilExpiration;
}
```

## Exception Handling

### Exception Hierarchy

All SDK exceptions inherit from `FrappeAuthException`:

- `FrappeNetworkException` - Network and HTTP errors
- `FrappeTokenException` - Token-related errors
- `FrappeConfigurationException` - Configuration errors
- `FrappeUserCancelledException` - User cancelled authentication
- `FrappePlatformException` - Platform setup errors

### Error Handling Example

```dart
try {
  final result = await client.login();
  if (result.isSuccess) {
    // Handle success
  } else {
    // Handle specific error types
    if (result.error is FrappeUserCancelledException) {
      print('User cancelled login');
    } else if (result.error is FrappeNetworkException) {
      print('Network error: ${result.error?.message}');
    } else {
      print('Authentication failed: ${result.error?.message}');
    }
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

## Platform Setup

### Android Setup

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true">
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="yourapp" />
    </intent-filter>
</activity>
```

### iOS Setup

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>yourapp.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

## Best Practices

### 1. Configuration Management

```dart
// Store configuration securely
class AuthConfig {
  static const config = OAuthConfig(
    baseUrl: String.fromEnvironment('FRAPPE_BASE_URL'),
    clientId: String.fromEnvironment('FRAPPE_CLIENT_ID'),
    redirectScheme: 'yourapp',
  );
}
```

### 2. Token Management

```dart
// Check authentication before API calls
Future<http.Response> makeAuthenticatedRequest(String endpoint) async {
  if (!await client.isAuthenticated()) {
    throw Exception('User not authenticated');
  }
  
  final token = await client.getAccessToken();
  return http.get(
    Uri.parse(endpoint),
    headers: {'Authorization': 'Bearer $token'},
  );
}
```

### 3. Error Handling

```dart
// Implement retry logic for token refresh
Future<String?> getValidToken() async {
  var token = await client.getAccessToken();
  
  if (token == null) {
    // Try to refresh
    final newTokens = await client.refreshToken();
    if (newTokens != null) {
      token = newTokens.accessToken;
    }
  }
  
  return token;
}
```

## Migration Guide

### From Other OAuth2 Libraries

1. **Replace initialization:**
   ```dart
   // Old
   final oauth = OAuth2Client(...);
   
   // New
   final client = await FrappeOAuthClient.create(config: config);
   ```

2. **Update authentication calls:**
   ```dart
   // Old
   final token = await oauth.getAccessToken();
   
   // New
   final result = await client.login();
   if (result.isSuccess) {
     final token = result.tokens?.accessToken;
   }
   ```

3. **Update state checking:**
   ```dart
   // Old
   if (oauth.hasValidToken()) { ... }
   
   // New
   if (await client.isAuthenticated()) { ... }
   ```
