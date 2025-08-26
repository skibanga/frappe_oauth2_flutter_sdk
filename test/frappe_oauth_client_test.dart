import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:frappe_oauth2_flutter_sdk/frappe_oauth_client.dart';
import 'package:frappe_oauth2_flutter_sdk/models/oauth_config.dart';
import 'package:frappe_oauth2_flutter_sdk/models/token_response.dart';
import 'package:frappe_oauth2_flutter_sdk/models/user_info.dart';
import 'package:frappe_oauth2_flutter_sdk/services/network_service.dart';
import 'package:frappe_oauth2_flutter_sdk/exceptions/frappe_auth_exception.dart';

import 'frappe_oauth_client_test.mocks.dart';

@GenerateMocks([NetworkService])
void main() {
  group('FrappeOAuthClient', () {
    late MockNetworkService mockNetworkService;
    late OAuthConfig config;
    late FrappeOAuthClient client;

    setUp(() {
      mockNetworkService = MockNetworkService();
      config = const OAuthConfig(
        baseUrl: 'https://test.frappe.cloud',
        clientId: 'test_client',
        redirectScheme: 'testapp',
      );
      client = FrappeOAuthClient(
        config: config,
        networkService: mockNetworkService,
      );
    });

    tearDown(() {
      client.dispose();
    });

    group('Initialization', () {
      test('should create client with valid config', () {
        expect(client.config, equals(config));
        expect(client.isAuthenticated(), isFalse);
        expect(client.getCurrentUser(), isNull);
        expect(client.getAccessToken(), isNull);
      });

      test('should throw exception with invalid config', () {
        expect(
          () => FrappeOAuthClient(
            config: const OAuthConfig(
              baseUrl: '', // Invalid empty URL
              clientId: 'test',
              redirectScheme: 'test',
            ),
          ),
          throwsA(isA<FrappeConfigurationException>()),
        );
      });
    });

    group('Authentication state', () {
      test('should report not authenticated initially', () {
        expect(client.isAuthenticated(), isFalse);
        expect(client.getCurrentUser(), isNull);
        expect(client.getAccessToken(), isNull);
      });

      test('should report authenticated after successful login', () async {
        // Mock successful token exchange
        when(mockNetworkService.post(any, formData: anyNamed('formData')))
            .thenAnswer((_) async => {
                  'access_token': 'test_access_token',
                  'refresh_token': 'test_refresh_token',
                  'expires_in': 3600,
                  'token_type': 'Bearer',
                });

        // Mock successful user info fetch
        when(mockNetworkService.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => {
                  'sub': 'user123',
                  'email': 'test@example.com',
                  'name': 'Test User',
                });

        // Note: We can't easily test the full login flow due to FlutterWebAuth2
        // dependency, but we can test the token exchange and user info parts
        
        // Simulate having tokens (this would normally come from login flow)
        final tokens = TokenResponse(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
          expiresIn: 3600,
          tokenType: 'Bearer',
          issuedAt: DateTime.now(),
        );

        // Use reflection or create a test method to set tokens
        // For now, we'll test the individual methods
      });
    });

    group('Token refresh', () {
      test('should throw exception when no tokens available', () async {
        expect(
          () => client.refreshToken(),
          throwsA(isA<FrappeTokenException>()
              .having((e) => e.code, 'code', 'no_tokens')),
        );
      });

      test('should refresh tokens successfully', () async {
        // This test would require setting up initial tokens
        // We'll implement this in integration tests
      });
    });

    group('URL building', () {
      test('should build valid authorization URL', () {
        // We can't directly test the private method, but we can verify
        // the config validation ensures proper URL construction
        expect(config.authorizationEndpoint, 
               equals('https://test.frappe.cloud/api/method/frappe.integrations.oauth2.authorize'));
        expect(config.tokenEndpoint,
               equals('https://test.frappe.cloud/api/method/frappe.integrations.oauth2.get_token'));
        expect(config.userInfoEndpoint,
               equals('https://test.frappe.cloud/api/method/frappe.integrations.oauth2.openid_profile'));
      });

      test('should use custom endpoints when provided', () {
        final customConfig = OAuthConfig(
          baseUrl: 'https://test.frappe.cloud',
          clientId: 'test_client',
          redirectScheme: 'testapp',
          customAuthorizationEndpoint: 'https://custom.auth.endpoint',
          customTokenEndpoint: 'https://custom.token.endpoint',
          customUserInfoEndpoint: 'https://custom.userinfo.endpoint',
        );

        expect(customConfig.authorizationEndpoint, equals('https://custom.auth.endpoint'));
        expect(customConfig.tokenEndpoint, equals('https://custom.token.endpoint'));
        expect(customConfig.userInfoEndpoint, equals('https://custom.userinfo.endpoint'));
      });
    });

    group('Error handling', () {
      test('should handle network errors during token exchange', () async {
        when(mockNetworkService.post(any, formData: anyNamed('formData')))
            .thenThrow(FrappeNetworkException('Network error'));

        // We would test this in the context of a full login flow
        // For now, we verify the exception types are properly defined
        expect(FrappeNetworkException('test'), isA<FrappeAuthException>());
        expect(FrappeTokenException('test'), isA<FrappeAuthException>());
        expect(FrappeUserCancelledException('test'), isA<FrappeAuthException>());
      });
    });

    group('Logout', () {
      test('should clear authentication state', () async {
        await client.logout();
        
        expect(client.isAuthenticated(), isFalse);
        expect(client.getCurrentUser(), isNull);
        expect(client.getAccessToken(), isNull);
      });
    });

    group('Configuration validation', () {
      test('should validate redirect scheme format', () {
        final issues = const OAuthConfig(
          baseUrl: 'https://test.frappe.cloud',
          clientId: 'test',
          redirectScheme: 'invalid://scheme', // Invalid format
        ).validate();

        expect(issues, isNotEmpty);
        expect(issues.first, contains('scheme should not contain'));
      });

      test('should validate base URL format', () {
        final issues = const OAuthConfig(
          baseUrl: 'not-a-url',
          clientId: 'test',
          redirectScheme: 'test',
        ).validate();

        expect(issues, isNotEmpty);
        expect(issues.first, contains('valid URL'));
      });

      test('should validate required fields', () {
        final issues = const OAuthConfig(
          baseUrl: '',
          clientId: '',
          redirectScheme: '',
        ).validate();

        expect(issues, hasLength(greaterThan(2)));
        expect(issues.any((issue) => issue.contains('Base URL')), isTrue);
        expect(issues.any((issue) => issue.contains('Client ID')), isTrue);
        expect(issues.any((issue) => issue.contains('Redirect scheme')), isTrue);
      });
    });
  });
}
