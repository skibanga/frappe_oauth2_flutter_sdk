import 'package:flutter_test/flutter_test.dart';
import 'package:frappe_oauth2_flutter_sdk/utils/url_builder.dart';
import 'package:frappe_oauth2_flutter_sdk/exceptions/frappe_auth_exception.dart';

void main() {
  group('UrlBuilder', () {
    group('buildAuthorizationUrl', () {
      test('should build valid authorization URL with all parameters', () {
        final url = UrlBuilder.buildAuthorizationUrl(
          baseUrl: 'https://test.frappe.cloud',
          clientId: 'test_client',
          redirectUri: 'myapp://oauth2redirect',
          scope: 'all openid',
          codeChallenge: 'test_challenge',
          state: 'test_state',
        );

        final uri = Uri.parse(url);
        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('test.frappe.cloud'));
        expect(
          uri.path,
          equals('/api/method/frappe.integrations.oauth2.authorize'),
        );
        expect(uri.queryParameters['client_id'], equals('test_client'));
        expect(uri.queryParameters['response_type'], equals('code'));
        expect(
          uri.queryParameters['redirect_uri'],
          equals('myapp://oauth2redirect'),
        );
        expect(uri.queryParameters['scope'], equals('all openid'));
        expect(uri.queryParameters['code_challenge'], equals('test_challenge'));
        expect(uri.queryParameters['code_challenge_method'], equals('S256'));
        expect(uri.queryParameters['state'], equals('test_state'));
      });

      test('should use custom endpoint when provided', () {
        final url = UrlBuilder.buildAuthorizationUrl(
          baseUrl: 'https://test.frappe.cloud',
          clientId: 'test_client',
          redirectUri: 'myapp://oauth2redirect',
          scope: 'all',
          codeChallenge: 'test_challenge',
          state: 'test_state',
          customEndpoint: 'https://custom.auth.endpoint',
        );

        final uri = Uri.parse(url);
        expect(uri.toString(), startsWith('https://custom.auth.endpoint'));
      });

      test('should include additional parameters', () {
        final url = UrlBuilder.buildAuthorizationUrl(
          baseUrl: 'https://test.frappe.cloud',
          clientId: 'test_client',
          redirectUri: 'myapp://oauth2redirect',
          scope: 'all',
          codeChallenge: 'test_challenge',
          state: 'test_state',
          additionalParams: {'custom_param': 'custom_value'},
        );

        final uri = Uri.parse(url);
        expect(uri.queryParameters['custom_param'], equals('custom_value'));
      });
    });

    group('buildTokenUrl', () {
      test('should build default token URL', () {
        final url = UrlBuilder.buildTokenUrl(
          baseUrl: 'https://test.frappe.cloud',
        );
        expect(
          url,
          equals(
            'https://test.frappe.cloud/api/method/frappe.integrations.oauth2.get_token',
          ),
        );
      });

      test('should use custom endpoint when provided', () {
        final url = UrlBuilder.buildTokenUrl(
          baseUrl: 'https://test.frappe.cloud',
          customEndpoint: 'https://custom.token.endpoint',
        );
        expect(url, equals('https://custom.token.endpoint'));
      });
    });

    group('buildUserInfoUrl', () {
      test('should build default user info URL', () {
        final url = UrlBuilder.buildUserInfoUrl(
          baseUrl: 'https://test.frappe.cloud',
        );
        expect(
          url,
          equals(
            'https://test.frappe.cloud/api/method/frappe.integrations.oauth2.openid_profile',
          ),
        );
      });

      test('should use custom endpoint when provided', () {
        final url = UrlBuilder.buildUserInfoUrl(
          baseUrl: 'https://test.frappe.cloud',
          customEndpoint: 'https://custom.userinfo.endpoint',
        );
        expect(url, equals('https://custom.userinfo.endpoint'));
      });
    });

    group('validateBaseUrl', () {
      test('should pass valid HTTPS URL', () {
        final issues = UrlBuilder.validateBaseUrl('https://test.frappe.cloud');
        expect(issues, isEmpty);
      });

      test('should pass valid HTTP URL', () {
        final issues = UrlBuilder.validateBaseUrl('http://localhost:8000');
        expect(issues, isEmpty);
      });

      test('should fail for empty URL', () {
        final issues = UrlBuilder.validateBaseUrl('');
        expect(issues, isNotEmpty);
        expect(issues.first, contains('cannot be empty'));
      });

      test('should fail for invalid URL', () {
        final issues = UrlBuilder.validateBaseUrl('not-a-url');
        expect(issues, isNotEmpty);
        expect(issues.first, contains('scheme'));
      });

      test('should fail for URL without scheme', () {
        final issues = UrlBuilder.validateBaseUrl('test.frappe.cloud');
        expect(issues, isNotEmpty);
        expect(issues.any((issue) => issue.contains('scheme')), isTrue);
      });

      test('should fail for invalid scheme', () {
        final issues = UrlBuilder.validateBaseUrl('ftp://test.frappe.cloud');
        expect(issues, isNotEmpty);
        expect(issues.any((issue) => issue.contains('http or https')), isTrue);
      });

      test('should warn about path in URL', () {
        final issues = UrlBuilder.validateBaseUrl(
          'https://test.frappe.cloud/path',
        );
        expect(issues, isNotEmpty);
        expect(issues.any((issue) => issue.contains('path')), isTrue);
      });
    });

    group('validateRedirectScheme', () {
      test('should pass valid scheme', () {
        final issues = UrlBuilder.validateRedirectScheme('myapp');
        expect(issues, isEmpty);
      });

      test('should pass scheme with numbers and allowed characters', () {
        final issues = UrlBuilder.validateRedirectScheme('myapp123');
        expect(issues, isEmpty);
      });

      test('should fail for empty scheme', () {
        final issues = UrlBuilder.validateRedirectScheme('');
        expect(issues, isNotEmpty);
        expect(issues.first, contains('cannot be empty'));
      });

      test('should fail for scheme with ://', () {
        final issues = UrlBuilder.validateRedirectScheme('myapp://');
        expect(issues, isNotEmpty);
        expect(
          issues.any((issue) => issue.contains('should not contain ://')),
          isTrue,
        );
      });

      test('should fail for reserved scheme', () {
        final issues = UrlBuilder.validateRedirectScheme('http');
        expect(issues, isNotEmpty);
        expect(
          issues.any((issue) => issue.contains('reserved scheme')),
          isTrue,
        );
      });

      test('should fail for invalid characters', () {
        final issues = UrlBuilder.validateRedirectScheme('my app');
        expect(issues, isNotEmpty);
        expect(
          issues.any((issue) => issue.contains('valid URL scheme')),
          isTrue,
        );
      });

      test('should warn about short scheme', () {
        final issues = UrlBuilder.validateRedirectScheme('ab');
        expect(issues, isNotEmpty);
        expect(
          issues.any((issue) => issue.contains('at least 3 characters')),
          isTrue,
        );
      });
    });

    group('validateScopes', () {
      test('should pass valid scopes', () {
        final issues = UrlBuilder.validateScopes(['all', 'openid', 'profile']);
        expect(issues, isEmpty);
      });

      test('should fail for empty scope list', () {
        final issues = UrlBuilder.validateScopes([]);
        expect(issues, isNotEmpty);
        expect(issues.first, contains('At least one scope'));
      });

      test('should fail for empty scope', () {
        final issues = UrlBuilder.validateScopes(['all', '', 'profile']);
        expect(issues, isNotEmpty);
        expect(
          issues.any((issue) => issue.contains('cannot be empty')),
          isTrue,
        );
      });

      test('should fail for scope with spaces', () {
        final issues = UrlBuilder.validateScopes(['all openid']);
        expect(issues, isNotEmpty);
        expect(
          issues.any((issue) => issue.contains('cannot contain spaces')),
          isTrue,
        );
      });

      test('should fail for scope with invalid characters', () {
        final issues = UrlBuilder.validateScopes(['all@invalid']);
        expect(issues, isNotEmpty);
        expect(
          issues.any((issue) => issue.contains('invalid characters')),
          isTrue,
        );
      });
    });

    group('validateClientId', () {
      test('should pass valid client ID', () {
        final issues = UrlBuilder.validateClientId('valid_client_123');
        expect(issues, isEmpty);
      });

      test('should fail for empty client ID', () {
        final issues = UrlBuilder.validateClientId('');
        expect(issues, isNotEmpty);
        expect(issues.first, contains('cannot be empty'));
      });

      test('should fail for short client ID', () {
        final issues = UrlBuilder.validateClientId('ab');
        expect(issues, isNotEmpty);
        expect(
          issues.any((issue) => issue.contains('at least 3 characters')),
          isTrue,
        );
      });

      test('should fail for client ID with spaces', () {
        final issues = UrlBuilder.validateClientId('client with spaces');
        expect(issues, isNotEmpty);
        expect(
          issues.any((issue) => issue.contains('should not contain spaces')),
          isTrue,
        );
      });
    });

    group('extractCallbackParams', () {
      test('should extract parameters from valid callback URL', () {
        final params = UrlBuilder.extractCallbackParams(
          'myapp://oauth2redirect?code=auth_code&state=test_state',
        );

        expect(params['code'], equals('auth_code'));
        expect(params['state'], equals('test_state'));
      });

      test('should throw exception for OAuth error', () {
        expect(
          () => UrlBuilder.extractCallbackParams(
            'myapp://oauth2redirect?error=access_denied&error_description=User%20denied',
          ),
          throwsA(
            isA<FrappeNetworkException>().having(
              (e) => e.code,
              'code',
              'access_denied',
            ),
          ),
        );
      });

      test('should handle invalid URL gracefully', () {
        // Note: Uri.tryParse is quite permissive, so we test with a truly invalid URL
        final params = UrlBuilder.extractCallbackParams('invalid-url');
        expect(params, isA<Map<String, String>>());
      });
    });

    group('validateCallbackUrl', () {
      test('should validate matching scheme', () {
        final isValid = UrlBuilder.validateCallbackUrl(
          'myapp://oauth2redirect?code=123',
          'myapp',
        );
        expect(isValid, isTrue);
      });

      test('should reject non-matching scheme', () {
        final isValid = UrlBuilder.validateCallbackUrl(
          'otherapp://oauth2redirect?code=123',
          'myapp',
        );
        expect(isValid, isFalse);
      });

      test('should handle case insensitive schemes', () {
        final isValid = UrlBuilder.validateCallbackUrl(
          'MyApp://oauth2redirect?code=123',
          'myapp',
        );
        expect(isValid, isTrue);
      });
    });
  });
}
