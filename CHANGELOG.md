# Changelog

## [0.1.0] - 2024-01-15

### Added
- Complete OAuth2 authorization code flow with PKCE support
- Cross-platform support (iOS, Android, Web, macOS, Windows, Linux)
- Headless design with no UI components - developers control the interface
- SharedPreferences-based token storage for simplicity
- Automatic token refresh functionality
- Comprehensive error handling with specific exception types
- 85+ unit tests with high code coverage
- Complete API documentation and guides

### Features
- Factory constructor pattern for clean initialization (`FrappeOAuthClient.create()`)
- Configuration validation to prevent common setup errors
- Deep link security validation for OAuth callbacks
- PKCE implementation for enhanced mobile security
- Support for custom scopes and redirect schemes
- Clean, intuitive API with helper getters (`isSuccess`, `isCancelled`, etc.)

### Documentation
- Quick start guide for 10-minute setup
- Complete API reference with examples
- Platform setup guides for all supported platforms
- Best practices documentation for security and architecture
- Comprehensive troubleshooting guide

### Security
- PKCE (Proof Key for Code Exchange) implementation
- Secure token storage with validation
- Deep link validation to prevent security issues
- Configuration validation to prevent misconfigurations
- No client secrets required (more secure for mobile apps)
