# Frappe OAuth2 Flutter SDK

A comprehensive Flutter SDK for Frappe OAuth2 authentication with automatic platform configuration and token management.

## Features

- 🔐 **Complete OAuth2 Flow**: Authorization code flow with PKCE support
- 🔄 **Automatic Token Refresh**: Background token refresh with configurable thresholds
- 💾 **Multiple Storage Options**: Secure storage, SharedPreferences, and Hive support
- 🛠️ **Platform Auto-Configuration**: Automatic Android and iOS setup
- 🌐 **Cross-Platform**: Works on Android, iOS, Web, and Desktop
- 🔍 **Comprehensive Validation**: Runtime configuration validation with helpful error messages
- 📱 **flutter_web_auth_2 Integration**: Seamless web authentication across platforms

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

// Initialize the client
final frappeAuth = FrappeOAuthClient(
  config: OAuthConfig(
    baseUrl: 'https://your-frappe-site.com',
    clientId: 'your-client-id',
    redirectScheme: 'myapp',
  ),
);

// Login
final result = await frappeAuth.login();
if (result.success) {
  print('Welcome ${result.userInfo!.fullName}');
} else {
  print('Login failed: ${result.error!.message}');
}

// Check authentication status
if (await frappeAuth.isAuthenticated()) {
  final user = await frappeAuth.getCurrentUser();
  print('Logged in as: ${user?.fullName}');
}

// Logout
await frappeAuth.logout();
```

## Project Structure

```
lib/
├── models/           # Data models (TokenResponse, UserInfo, etc.)
├── services/         # Core services
│   └── storage/      # Storage implementations
├── utils/            # Utility functions
├── exceptions/       # Custom exceptions
└── frappe_oauth_client.dart  # Main client class
```

## Development Status

✅ **Phase 1 Complete** - Foundation & Core Architecture

- [x] Project setup and dependencies
- [x] Core data models (TokenResponse, UserInfo, AuthResult, OAuthConfig)
- [x] Exception hierarchy (comprehensive error handling)
- [x] Network service (HTTP client with retry logic)
- [x] Basic OAuth2 client (complete authorization code flow)
- [x] URL construction & validation (comprehensive validation utilities)

🚧 **Next: Phase 2** - Platform Integration & Storage

- [ ] Storage service implementations
- [ ] flutter_web_auth_2 integration
- [ ] Token manager with persistence
- [ ] Manual platform configuration guides
- [ ] Enhanced example app

## Contributing

This project is currently in active development. Contributions will be welcome once the initial implementation is complete.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

