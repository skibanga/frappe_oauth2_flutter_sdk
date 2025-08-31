# Frappe OAuth2 Flutter SDK

A clean, headless Flutter SDK for OAuth2 authentication with Frappe servers. This SDK provides a simplified, developer-friendly API without UI components, allowing you to integrate OAuth2 authentication seamlessly into your Flutter applications.

## ✨ Features

- **🔐 Complete OAuth2 Flow** - Authorization code flow with PKCE support
- **📱 Cross-Platform** - iOS, Android, Web, macOS, Windows, Linux
- **🎯 Headless Design** - No UI components, you control the interface
- **💾 Simple Storage** - SharedPreferences-based token storage
- **🔄 Auto Token Refresh** - Automatic token management
- **🛡️ Secure** - PKCE implementation, secure token handling
- **🧪 Well Tested** - 85+ unit tests with comprehensive coverage
- **📚 Comprehensive Docs** - Detailed guides and API reference

## Quick Start

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  frappe_oauth2_flutter_sdk: ^0.1.0
```

### Basic Usage

```dart
import 'package:frappe_oauth2_flutter_sdk/frappe_oauth2_flutter_sdk.dart';

// 1. Configure
final config = OAuthConfig(
  baseUrl: 'https://your-frappe-server.com',
  clientId: 'your-client-id',
  redirectScheme: 'yourapp',
  scopes: ['openid', 'profile', 'email'],
);

// 2. Create client
final client = await FrappeOAuthClient.create(config: config);

// 3. Login
final result = await client.login();
if (result.isSuccess) {
  print('Logged in as: ${result.userInfo?.email}');
} else if (result.isCancelled) {
  print('User cancelled login');
} else {
  print('Login failed: ${result.error?.message}');
}

// 4. Check authentication
if (await client.isAuthenticated()) {
  final token = await client.getAccessToken();
  // Use token for API calls
}

// 5. Logout
await client.logout();
```

## 📋 Platform Setup

### Android
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

### iOS
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

## 📚 Documentation

- **[Quick Start Guide](doc/quick_start.md)** - Get up and running in 10 minutes
- **[API Reference](doc/api_reference.md)** - Complete API documentation
- **[Platform Setup](doc/platform_setup.md)** - Detailed platform configuration
- **[Best Practices](doc/best_practices.md)** - Security and architecture patterns

## 🧪 Testing

The SDK includes comprehensive unit tests with 85+ test cases:

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 🔧 API Overview

### Core Classes
- **`FrappeOAuthClient`** - Main authentication client
- **`OAuthConfig`** - Configuration settings
- **`AuthResult`** - Authentication result wrapper
- **`UserInfo`** - User profile information
- **`TokenResponse`** - OAuth2 token data

### Key Methods
```dart
// Factory constructor
static Future<FrappeOAuthClient> create({required OAuthConfig config})

// Authentication
Future<AuthResult> login()
Future<void> logout()

// State management
Future<bool> isAuthenticated()
Future<UserInfo?> getCurrentUser()
Future<String?> getAccessToken()
Future<TokenResponse?> refreshToken()
```

## 🛡️ Security Features

- **PKCE Implementation** - Proof Key for Code Exchange
- **Secure Token Storage** - SharedPreferences with validation
- **Automatic Token Refresh** - Background token management
- **Deep Link Validation** - Secure callback URL handling
- **Configuration Validation** - Prevents common setup errors

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ for the Frappe community

