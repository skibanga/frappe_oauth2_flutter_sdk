import 'package:flutter/material.dart';
import 'package:frappe_oauth2_flutter_sdk/frappe_oauth2_flutter_sdk.dart';

/// Simple usage example for the Frappe OAuth2 Flutter SDK
/// 
/// This demonstrates the clean, headless API without any UI components
/// from the SDK itself. Developers provide their own UI.
class SimpleUsageExample extends StatefulWidget {
  const SimpleUsageExample({super.key});

  @override
  State<SimpleUsageExample> createState() => _SimpleUsageExampleState();
}

class _SimpleUsageExampleState extends State<SimpleUsageExample> {
  FrappeOAuthClient? _client;
  bool _isLoading = false;
  String _status = 'Not authenticated';
  UserInfo? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeClient();
  }

  Future<void> _initializeClient() async {
    try {
      // 1. Configure the OAuth client
      final config = OAuthConfig(
        baseUrl: 'https://your-frappe-server.com',
        clientId: 'your-client-id',
        redirectScheme: 'yourapp',
        scopes: ['openid', 'profile', 'email'],
        enableLogging: true,
      );

      // 2. Create the client
      _client = await FrappeOAuthClient.create(config: config);

      // 3. Check if already authenticated
      final isAuthenticated = await _client!.isAuthenticated();
      if (isAuthenticated) {
        final user = await _client!.getCurrentUser();
        setState(() {
          _status = 'Already authenticated';
          _currentUser = user;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _login() async {
    if (_client == null) return;

    setState(() {
      _isLoading = true;
      _status = 'Logging in...';
    });

    try {
      // 4. Perform login
      final result = await _client!.login();

      if (result.isSuccess) {
        setState(() {
          _status = 'Login successful!';
          _currentUser = result.userInfo;
        });
      } else if (result.isCancelled) {
        setState(() {
          _status = 'Login cancelled by user';
        });
      } else {
        setState(() {
          _status = 'Login failed: ${result.error?.message}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Login error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    if (_client == null) return;

    setState(() {
      _isLoading = true;
      _status = 'Logging out...';
    });

    try {
      // 5. Perform logout
      await _client!.logout();
      setState(() {
        _status = 'Logged out successfully';
        _currentUser = null;
      });
    } catch (e) {
      setState(() {
        _status = 'Logout error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshToken() async {
    if (_client == null) return;

    setState(() {
      _isLoading = true;
      _status = 'Refreshing token...';
    });

    try {
      final newTokens = await _client!.refreshToken();
      if (newTokens != null) {
        setState(() {
          _status = 'Token refreshed successfully';
        });
      } else {
        setState(() {
          _status = 'Token refresh failed';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Token refresh error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAccessToken() async {
    if (_client == null) return;

    try {
      final token = await _client!.getAccessToken();
      if (token != null) {
        setState(() {
          _status = 'Access token: ${token.substring(0, 20)}...';
        });
      } else {
        setState(() {
          _status = 'No access token available';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Get token error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frappe OAuth2 SDK Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_currentUser != null) ...[
                      const SizedBox(height: 8),
                      Text('User: ${_currentUser!.email}'),
                      Text('Name: ${_currentUser!.fullName}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: _currentUser == null ? _login : null,
                child: const Text('Login'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _currentUser != null ? _logout : null,
                child: const Text('Logout'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _currentUser != null ? _refreshToken : null,
                child: const Text('Refresh Token'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _currentUser != null ? _getAccessToken : null,
                child: const Text('Get Access Token'),
              ),
            ],

            const SizedBox(height: 32),

            // Usage instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usage Instructions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Update the config with your Frappe server details\n'
                      '2. Configure platform-specific redirect schemes\n'
                      '3. Test the login flow\n'
                      '4. Use the access token for API calls',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _client?.dispose();
    super.dispose();
  }
}
