# Quick Start Guide - Frappe OAuth2 Flutter SDK

## Overview

Get up and running with Frappe OAuth2 authentication in your Flutter app in under 10 minutes.

## Prerequisites

- Flutter 3.0+ 
- Dart 3.0+
- A Frappe server with OAuth2 configured
- OAuth2 client credentials from your Frappe server

## Installation

### 1. Add Dependency

Add to your `pubspec.yaml`:

```yaml
dependencies:
  frappe_oauth2_flutter_sdk: ^1.0.0
```

Run:
```bash
flutter pub get
```

### 2. Platform Setup

#### Android Setup

Add to `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

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

#### iOS Setup

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

**Important:** Replace `yourapp` with your actual app's custom URL scheme.

## Basic Implementation

### 1. Create Configuration

```dart
import 'package:frappe_oauth2_flutter_sdk/frappe_oauth2_flutter_sdk.dart';

final config = OAuthConfig(
  baseUrl: 'https://your-frappe-server.com',
  clientId: 'your-client-id',
  redirectScheme: 'yourapp', // Must match platform setup
  scopes: ['openid', 'profile', 'email'],
);
```

### 2. Initialize Client

```dart
class AuthService {
  static FrappeOAuthClient? _client;
  
  static Future<FrappeOAuthClient> getClient() async {
    _client ??= await FrappeOAuthClient.create(config: config);
    return _client!;
  }
}
```

### 3. Implement Login

```dart
Future<void> login() async {
  try {
    final client = await AuthService.getClient();
    final result = await client.login();
    
    if (result.isSuccess) {
      // Login successful
      print('Welcome ${result.userInfo?.email}!');
      
      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    } else if (result.isCancelled) {
      // User cancelled
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login cancelled')),
      );
    } else {
      // Login failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${result.error?.message}')),
      );
    }
  } catch (e) {
    print('Login error: $e');
  }
}
```

### 4. Check Authentication Status

```dart
Future<bool> checkAuthStatus() async {
  try {
    final client = await AuthService.getClient();
    return await client.isAuthenticated();
  } catch (e) {
    return false;
  }
}
```

### 5. Make Authenticated API Calls

```dart
Future<Map<String, dynamic>?> fetchUserProfile() async {
  try {
    final client = await AuthService.getClient();
    
    if (!await client.isAuthenticated()) {
      throw Exception('User not authenticated');
    }
    
    final token = await client.getAccessToken();
    final response = await http.get(
      Uri.parse('${config.baseUrl}/api/method/frappe.auth.get_logged_user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch profile');
    }
  } catch (e) {
    print('Error fetching profile: $e');
    return null;
  }
}
```

### 6. Implement Logout

```dart
Future<void> logout() async {
  try {
    final client = await AuthService.getClient();
    await client.logout();
    
    // Navigate to login screen
    Navigator.pushReplacementNamed(context, '/login');
  } catch (e) {
    print('Logout error: $e');
  }
}
```

## Complete Example App

### main.dart

```dart
import 'package:flutter/material.dart';
import 'package:frappe_oauth2_flutter_sdk/frappe_oauth2_flutter_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frappe OAuth Demo',
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? isAuthenticated;
  
  @override
  void initState() {
    super.initState();
    checkAuthStatus();
  }
  
  Future<void> checkAuthStatus() async {
    final client = await AuthService.getClient();
    final authenticated = await client.isAuthenticated();
    setState(() {
      isAuthenticated = authenticated;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (isAuthenticated == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return isAuthenticated! ? HomeScreen() : LoginScreen();
  }
}
```

### login_screen.dart

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Frappe App',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _login(context),
              child: Text('Login with Frappe'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _login(BuildContext context) async {
    try {
      final client = await AuthService.getClient();
      final result = await client.login();
      
      if (result.isSuccess) {
        // Refresh the app to show home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else if (!result.isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${result.error?.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    }
  }
}
```

### home_screen.dart

```dart
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserInfo? user;
  
  @override
  void initState() {
    super.initState();
    loadUser();
  }
  
  Future<void> loadUser() async {
    final client = await AuthService.getClient();
    final userInfo = await client.getCurrentUser();
    setState(() {
      user = userInfo;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user != null) ...[
              Text('Welcome, ${user!.fullName ?? user!.email}!'),
              SizedBox(height: 16),
              Text('Email: ${user!.email}'),
            ] else
              CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
  
  Future<void> _logout(BuildContext context) async {
    final client = await AuthService.getClient();
    await client.logout();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}
```

## Configuration Tips

### Environment Variables

Use environment variables for sensitive configuration:

```dart
final config = OAuthConfig(
  baseUrl: const String.fromEnvironment(
    'FRAPPE_BASE_URL',
    defaultValue: 'https://demo.frappe.cloud',
  ),
  clientId: const String.fromEnvironment('FRAPPE_CLIENT_ID'),
  redirectScheme: 'yourapp',
);
```

Run with:
```bash
flutter run --dart-define=FRAPPE_BASE_URL=https://your-server.com --dart-define=FRAPPE_CLIENT_ID=your-client-id
```

### Development vs Production

```dart
class AppConfig {
  static const bool isDevelopment = bool.fromEnvironment('DEBUG', defaultValue: false);
  
  static OAuthConfig get oauthConfig => OAuthConfig(
    baseUrl: isDevelopment 
      ? 'https://dev.frappe.cloud' 
      : 'https://prod.frappe.cloud',
    clientId: isDevelopment ? 'dev_client' : 'prod_client',
    redirectScheme: 'yourapp',
    enableLogging: isDevelopment,
  );
}
```

## Troubleshooting

### Common Issues

1. **"No registered scheme handler"**
   - Ensure platform setup is correct
   - Verify redirect scheme matches configuration

2. **"Invalid client"**
   - Check client ID in Frappe server
   - Verify OAuth2 app is enabled

3. **"Invalid redirect URI"**
   - Add redirect URI to Frappe OAuth2 app settings
   - Format: `yourapp://oauth2redirect`

### Debug Mode

Enable logging for debugging:

```dart
final config = OAuthConfig(
  // ... other config
  enableLogging: true,
);
```

## Next Steps

- Read the [API Reference](api_reference.md) for detailed documentation
- Check [Platform Setup](platform_setup.md) for advanced configuration
- See [Best Practices](best_practices.md) for production recommendations
