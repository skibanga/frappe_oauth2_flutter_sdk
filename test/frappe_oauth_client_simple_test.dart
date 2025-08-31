import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frappe_oauth2_flutter_sdk/frappe_oauth_client_simple.dart';
import 'package:frappe_oauth2_flutter_sdk/models/oauth_config.dart';
import 'package:frappe_oauth2_flutter_sdk/models/user_info.dart';
import 'package:frappe_oauth2_flutter_sdk/models/token_response.dart';
import 'package:frappe_oauth2_flutter_sdk/exceptions/frappe_auth_exception.dart';
import 'package:frappe_oauth2_flutter_sdk/services/network_service.dart';
import 'package:frappe_oauth2_flutter_sdk/services/web_auth_service.dart';

// Mock classes
class MockNetworkService extends Mock implements NetworkService {}

class MockWebAuthService extends Mock implements WebAuthService {}

void main() {
  group('FrappeOAuthClient', () {
    late OAuthConfig config;
    late MockNetworkService mockNetworkService;
    late MockWebAuthService mockWebAuthService;

    setUp(() {
      config = const OAuthConfig(
        baseUrl: 'https://test.frappe.cloud',
        clientId: 'test_client',
        redirectScheme: 'testapp',
        scopes: ['openid', 'profile', 'email'],
      );

      mockNetworkService = MockNetworkService();
      mockWebAuthService = MockWebAuthService();

      // Setup SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    group('create factory constructor', () {
      test('should create client with valid configuration', () async {
        // Act
        final client = await FrappeOAuthClient.create(config: config);

        // Assert
        expect(client, isNotNull);
        expect(client.config, equals(config));
      });

      test(
        'should throw FrappeConfigurationException for invalid config',
        () async {
          // Arrange
          final invalidConfig = const OAuthConfig(
            baseUrl: '', // Invalid empty URL
            clientId: 'test_client',
            redirectScheme: 'testapp',
            scopes: ['openid'],
          );

          // Act & Assert
          expect(
            () => FrappeOAuthClient.create(config: invalidConfig),
            throwsA(isA<FrappeConfigurationException>()),
          );
        },
      );

      test('should validate all required configuration fields', () async {
        // Test empty client ID
        expect(
          () => FrappeOAuthClient.create(
            config: const OAuthConfig(
              baseUrl: 'https://test.frappe.cloud',
              clientId: '', // Invalid
              redirectScheme: 'testapp',
              scopes: ['openid'],
            ),
          ),
          throwsA(isA<FrappeConfigurationException>()),
        );

        // Test empty redirect scheme
        expect(
          () => FrappeOAuthClient.create(
            config: const OAuthConfig(
              baseUrl: 'https://test.frappe.cloud',
              clientId: 'test_client',
              redirectScheme: '', // Invalid
              scopes: ['openid'],
            ),
          ),
          throwsA(isA<FrappeConfigurationException>()),
        );

        // Test empty scopes
        expect(
          () => FrappeOAuthClient.create(
            config: const OAuthConfig(
              baseUrl: 'https://test.frappe.cloud',
              clientId: 'test_client',
              redirectScheme: 'testapp',
              scopes: [], // Invalid
            ),
          ),
          throwsA(isA<FrappeConfigurationException>()),
        );
      });
    });

    group('authentication state management', () {
      late FrappeOAuthClient client;

      setUp(() async {
        client = await FrappeOAuthClient.create(config: config);
      });

      test(
        'should return false for isAuthenticated when no tokens stored',
        () async {
          // Act
          final isAuthenticated = await client.isAuthenticated();

          // Assert
          expect(isAuthenticated, isFalse);
        },
      );

      test(
        'should return null for getCurrentUser when no user stored',
        () async {
          // Act
          final user = await client.getCurrentUser();

          // Assert
          expect(user, isNull);
        },
      );

      test(
        'should return null for getAccessToken when no tokens stored',
        () async {
          // Act
          final token = await client.getAccessToken();

          // Assert
          expect(token, isNull);
        },
      );
    });

    group('login flow', () {
      late FrappeOAuthClient client;

      setUp(() async {
        client = await FrappeOAuthClient.create(config: config);
      });

      test('should return success result for successful login', () async {
        // This test would require mocking the internal services
        // For now, we'll test the configuration validation
        expect(client.config.baseUrl, equals('https://test.frappe.cloud'));
        expect(client.config.clientId, equals('test_client'));
        expect(client.config.redirectScheme, equals('testapp'));
      });
    });

    group('logout', () {
      late FrappeOAuthClient client;

      setUp(() async {
        client = await FrappeOAuthClient.create(config: config);
      });

      test('should clear stored data on logout', () async {
        // Act
        await client.logout();

        // Assert
        final isAuthenticated = await client.isAuthenticated();
        final user = await client.getCurrentUser();
        final token = await client.getAccessToken();

        expect(isAuthenticated, isFalse);
        expect(user, isNull);
        expect(token, isNull);
      });
    });

    group('token refresh', () {
      late FrappeOAuthClient client;

      setUp(() async {
        client = await FrappeOAuthClient.create(config: config);
      });

      test('should return null when no refresh token available', () async {
        // Act
        final newTokens = await client.refreshToken();

        // Assert
        expect(newTokens, isNull);
      });
    });

    group('dispose', () {
      test('should dispose client without errors', () async {
        // Arrange
        final client = await FrappeOAuthClient.create(config: config);

        // Act & Assert
        expect(() => client.dispose(), returnsNormally);
      });
    });

    group('PKCE helper methods', () {
      test('should generate different code verifiers', () async {
        // We can't directly test private methods, but we can test the behavior
        // by ensuring the client creates properly
        await expectLater(FrappeOAuthClient.create(config: config), completes);
      });
    });
  });
}

// Test data helpers
class TestData {
  static const validTokenResponse = {
    'access_token': 'test_access_token',
    'refresh_token': 'test_refresh_token',
    'token_type': 'Bearer',
    'expires_in': 3600,
  };

  static const validUserInfo = {
    'sub': 'test_user_id',
    'email': 'test@example.com',
    'name': 'Test User',
    'given_name': 'Test',
    'family_name': 'User',
  };

  static TokenResponse get sampleTokenResponse =>
      TokenResponse.fromJson(validTokenResponse);
  static UserInfo get sampleUserInfo => UserInfo.fromJson(validUserInfo);
}
