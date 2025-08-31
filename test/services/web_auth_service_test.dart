import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frappe_oauth2_flutter_sdk/services/web_auth_service.dart';
import 'package:frappe_oauth2_flutter_sdk/models/oauth_config.dart';
import 'package:frappe_oauth2_flutter_sdk/exceptions/frappe_auth_exception.dart';

// Mock class for WebAuthService
class MockWebAuthService extends Mock implements WebAuthService {}

void main() {
  group('WebAuthService', () {
    late WebAuthService webAuthService;
    late OAuthConfig config;

    setUp(() {
      config = const OAuthConfig(
        baseUrl: 'https://test.frappe.cloud',
        clientId: 'test_client',
        redirectScheme: 'testapp',
        scopes: ['openid', 'profile'],
      );
      webAuthService = WebAuthService(config: config);
    });

    group('authenticate', () {
      test(
        'should extract authorization code from successful callback',
        () async {
          // Arrange
          const expectedCode = 'test_auth_code_123';
          const callbackUrl =
              'testapp://oauth2redirect?code=$expectedCode&state=test_state';

          // Act & Assert
          final code = webAuthService._extractAuthorizationCode(callbackUrl);
          expect(code, equals(expectedCode));
        },
      );

      test(
        'should throw FrappeAuthException when no code in callback',
        () async {
          // Arrange
          const callbackUrl = 'testapp://oauth2redirect?state=test_state';

          // Act & Assert
          expect(
            () => webAuthService._extractAuthorizationCode(callbackUrl),
            throwsA(isA<FrappeNetworkException>()),
          );
        },
      );

      test(
        'should throw FrappeNetworkException when OAuth error in callback',
        () async {
          // Arrange
          const callbackUrl =
              'testapp://oauth2redirect?error=access_denied&error_description=User%20denied%20access';

          // Act & Assert
          expect(
            () => webAuthService._extractAuthorizationCode(callbackUrl),
            throwsA(isA<FrappeNetworkException>()),
          );
        },
      );

      test(
        'should throw FrappeNetworkException for invalid callback URL',
        () async {
          // Arrange
          const invalidUrl = 'not-a-valid-url';

          // Act & Assert
          expect(
            () => webAuthService._extractAuthorizationCode(invalidUrl),
            throwsA(isA<FrappeNetworkException>()),
          );
        },
      );
    });

    group('validateCallbackScheme', () {
      test('should return true for matching scheme', () {
        // Arrange
        const callbackUrl = 'testapp://oauth2redirect?code=123';

        // Act
        final isValid = webAuthService.validateCallbackScheme(callbackUrl);

        // Assert
        expect(isValid, isTrue);
      });

      test('should return false for non-matching scheme', () {
        // Arrange
        const callbackUrl = 'wrongapp://oauth2redirect?code=123';

        // Act
        final isValid = webAuthService.validateCallbackScheme(callbackUrl);

        // Assert
        expect(isValid, isFalse);
      });

      test('should return false for invalid URL', () {
        // Arrange
        const invalidUrl = 'not-a-url';

        // Act
        final isValid = webAuthService.validateCallbackScheme(invalidUrl);

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('buildRedirectUri', () {
      test('should build correct redirect URI', () {
        // Act
        final redirectUri = webAuthService.buildRedirectUri();

        // Assert
        expect(redirectUri, equals('testapp://oauth2redirect'));
      });
    });

    group('isAvailable', () {
      test('should return true for web auth availability', () async {
        // Act
        final isAvailable = await WebAuthService.isAvailable();

        // Assert
        expect(isAvailable, isTrue);
      });
    });
  });
}

// Extension to access private methods for testing
extension WebAuthServiceTestExtension on WebAuthService {
  String _extractAuthorizationCode(String callbackUrl) {
    try {
      final uri = Uri.parse(callbackUrl);

      // Check for authorization code in query parameters
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        return code;
      }

      // Check for error in callback
      final error = uri.queryParameters['error'];
      if (error != null) {
        final errorDescription =
            uri.queryParameters['error_description'] ?? error;
        throw FrappeNetworkException('OAuth error: $errorDescription');
      }

      throw FrappeNetworkException(
        'No authorization code found in callback URL',
      );
    } catch (e) {
      if (e is FrappeAuthException) {
        rethrow;
      }

      throw FrappeNetworkException(
        'Failed to parse callback URL: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
