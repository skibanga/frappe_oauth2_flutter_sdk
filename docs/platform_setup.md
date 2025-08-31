# Platform Setup Guide - Frappe OAuth2 Flutter SDK

## Overview

This guide provides detailed platform-specific setup instructions for Android, iOS, Web, macOS, Windows, and Linux.

## Android Setup

### 1. Manifest Configuration

Add the following to `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

```xml
<!-- OAuth2 Callback Activity -->
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:launchMode="singleTop">
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="yourapp" />
    </intent-filter>
</activity>
```

### 2. ProGuard Configuration (if using)

Add to `android/app/proguard-rules.pro`:

```proguard
-keep class com.linusu.flutter_web_auth_2.** { *; }
-keep class androidx.browser.** { *; }
```

### 3. Network Security Configuration

For development with HTTP servers, add to `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">your-dev-server.com</domain>
    </domain-config>
</network-security-config>
```

Reference in `AndroidManifest.xml`:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

### 4. Minimum SDK Version

Ensure `android/app/build.gradle` has:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // Minimum required
        targetSdkVersion 34
    }
}
```

## iOS Setup

### 1. URL Scheme Configuration

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

### 2. iOS Deployment Target

Ensure `ios/Podfile` has:

```ruby
platform :ios, '12.0'  # Minimum required
```

### 3. App Transport Security (if needed)

For development with HTTP servers, add to `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>your-dev-server.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 4. Privacy Usage Descriptions

Add to `Info.plist` if your app accesses user data:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This app uses authentication to provide personalized content.</string>
```

## Web Setup

### 1. Web Configuration

No additional setup required for web. The SDK automatically handles web authentication using popup windows.

### 2. CORS Configuration

Ensure your Frappe server allows your web domain in CORS settings:

```python
# In Frappe server site_config.json
{
    "allow_cors": "*",
    "cors_allow_credentials": true
}
```

### 3. HTTPS Requirement

Web OAuth2 requires HTTPS in production. For development, you can use:

```bash
flutter run -d chrome --web-hostname localhost --web-port 3000
```

## macOS Setup

### 1. URL Scheme Configuration

Add to `macos/Runner/Info.plist`:

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

### 2. Entitlements

Add to `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

### 3. Minimum macOS Version

Ensure `macos/Runner.xcodeproj/project.pbxproj` has:

```
MACOSX_DEPLOYMENT_TARGET = 10.14;
```

## Windows Setup

### 1. URL Protocol Registration

The SDK automatically handles URL protocol registration on Windows. No manual setup required.

### 2. Minimum Windows Version

Ensure your app targets Windows 10 version 1903 or later in `windows/runner/main.cpp`.

## Linux Setup

### 1. URL Handler Registration

The SDK automatically handles URL protocol registration on Linux. No manual setup required.

### 2. Dependencies

Ensure required system dependencies are installed:

```bash
sudo apt-get install libwebkit2gtk-4.0-dev
```

## Custom URL Scheme Best Practices

### 1. Scheme Naming

Choose a unique scheme name:

```dart
// Good examples
redirectScheme: 'mycompanyapp'
redirectScheme: 'com.mycompany.myapp'

// Avoid generic names
redirectScheme: 'app'  // Too generic
redirectScheme: 'oauth'  // Too common
```

### 2. Scheme Validation

The SDK validates schemes automatically, but ensure:

- No spaces or special characters
- Starts with a letter
- Uses only letters, numbers, hyphens, and dots
- Avoid reserved schemes (http, https, ftp, etc.)

### 3. Multiple Environments

Use different schemes for different environments:

```dart
class AppConfig {
  static String get redirectScheme {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    switch (environment) {
      case 'prod':
        return 'myapp';
      case 'staging':
        return 'myapp-staging';
      default:
        return 'myapp-dev';
    }
  }
}
```

## Frappe Server Configuration

### 1. OAuth2 App Setup

In your Frappe server, create an OAuth2 app:

1. Go to **Setup > Integrations > OAuth Client**
2. Create new OAuth Client with:
   - **App Name**: Your app name
   - **Client ID**: Generate or set custom ID
   - **Default Redirect URI**: `yourapp://oauth2redirect`
   - **Grant Type**: Authorization Code
   - **Response Type**: Code

### 2. Redirect URI Configuration

Add all platform redirect URIs:

```
yourapp://oauth2redirect          # Mobile/Desktop
http://localhost:3000/auth        # Web development
https://yourapp.com/auth          # Web production
```

### 3. Scope Configuration

Configure required scopes in the OAuth2 app:

- `openid` - Required for OpenID Connect
- `profile` - User profile information
- `email` - User email address
- `offline_access` - Refresh tokens (if supported)

### 4. CORS Settings

Update site configuration for web support:

```json
{
  "allow_cors": [
    "http://localhost:3000",
    "https://yourapp.com"
  ],
  "cors_allow_credentials": true
}
```

## Troubleshooting

### Common Platform Issues

#### Android

**Issue**: "No Activity found to handle Intent"
**Solution**: Verify manifest configuration and scheme name

**Issue**: "cleartext HTTP traffic not permitted"
**Solution**: Add network security configuration for development

#### iOS

**Issue**: "Invalid URL scheme"
**Solution**: Check Info.plist configuration and scheme format

**Issue**: App doesn't open after authentication
**Solution**: Verify URL scheme matches exactly

#### Web

**Issue**: CORS errors
**Solution**: Configure Frappe server CORS settings

**Issue**: Popup blocked
**Solution**: Ensure user interaction triggers authentication

### Debug Tools

#### Enable Debug Logging

```dart
final config = OAuthConfig(
  // ... other settings
  enableLogging: true,
);
```

#### Test URL Scheme

Test your URL scheme manually:

```bash
# Android
adb shell am start -W -a android.intent.action.VIEW -d "yourapp://test"

# iOS Simulator
xcrun simctl openurl booted "yourapp://test"

# macOS
open "yourapp://test"
```

#### Verify Frappe OAuth2 Setup

Test OAuth2 endpoints manually:

```bash
# Authorization endpoint
curl "https://your-server.com/api/method/frappe.integrations.oauth2.authorize?client_id=your-client&response_type=code&redirect_uri=yourapp://oauth2redirect"

# Token endpoint
curl -X POST "https://your-server.com/api/method/frappe.integrations.oauth2.get_token" \
  -d "grant_type=authorization_code&client_id=your-client&code=auth-code&redirect_uri=yourapp://oauth2redirect"
```

## Security Considerations

### 1. Redirect URI Validation

Always use exact redirect URI matching in production:

```
yourapp://oauth2redirect  ✓ Secure
yourapp://*              ✗ Insecure
```

### 2. Client Secret

This SDK uses PKCE (Proof Key for Code Exchange) instead of client secrets, which is more secure for mobile apps.

### 3. Deep Link Security

Validate deep links in your app:

```dart
// Validate the source of deep links
bool isValidAuthCallback(String url) {
  final uri = Uri.parse(url);
  return uri.scheme == 'yourapp' && 
         uri.host == 'oauth2redirect';
}
```

### 4. Token Storage

The SDK uses SharedPreferences for token storage. For enhanced security, consider:

- Enabling device encryption
- Using biometric authentication
- Implementing token rotation

## Production Checklist

- [ ] Custom URL scheme configured on all platforms
- [ ] Frappe OAuth2 app configured with correct redirect URIs
- [ ] HTTPS used for all production servers
- [ ] CORS configured for web domains
- [ ] Debug logging disabled in production
- [ ] URL scheme validation implemented
- [ ] Deep link security measures in place
- [ ] Token refresh handling implemented
- [ ] Error handling for all authentication scenarios
