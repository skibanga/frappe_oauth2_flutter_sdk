import 'package:flutter_test/flutter_test.dart';
import 'package:frappe_oauth2_flutter_sdk/exceptions/frappe_auth_exception.dart';

void main() {
  group('FrappeAuthException', () {
    test('FrappeNetworkException should handle HTTP errors', () {
      final exception = FrappeNetworkException(
        'Network request failed',
        code: 'network_error',
        statusCode: 404,
        responseBody: '{"error": "Not found"}',
      );

      expect(exception.message, equals('Network request failed'));
      expect(exception.code, equals('network_error'));
      expect(exception.statusCode, equals(404));
      expect(exception.responseBody, equals('{"error": "Not found"}'));
      expect(exception.isClientError, isTrue);
      expect(exception.isServerError, isFalse);
      expect(exception.isTimeout, isFalse);
    });

    test('FrappeNetworkException should detect server errors', () {
      final exception = FrappeNetworkException(
        'Internal server error',
        statusCode: 500,
      );

      expect(exception.isClientError, isFalse);
      expect(exception.isServerError, isTrue);
    });

    test('FrappeNetworkException should detect timeout errors', () {
      final timeoutException = FrappeNetworkException(
        'Request timeout',
        code: 'timeout',
      );

      final timeoutException2 = FrappeNetworkException(
        'Connection timeout occurred',
      );

      expect(timeoutException.isTimeout, isTrue);
      expect(timeoutException2.isTimeout, isTrue);
      expect(timeoutException.friendlyMessage, contains('timed out'));
    });

    test('FrappeTokenException should handle token errors', () {
      final exception = FrappeTokenException(
        'Token has expired',
        code: 'expired_token',
        tokenHint: 'eyJ...',
      );

      expect(exception.message, equals('Token has expired'));
      expect(exception.code, equals('expired_token'));
      expect(exception.tokenHint, equals('eyJ...'));
      expect(exception.friendlyMessage, contains('session has expired'));
    });

    test('FrappeTokenException should provide appropriate friendly messages', () {
      final expiredToken = FrappeTokenException(
        'Token expired',
        code: 'expired_token',
      );

      final invalidToken = FrappeTokenException(
        'Invalid token',
        code: 'invalid_token',
      );

      final refreshFailed = FrappeTokenException(
        'Refresh failed',
        code: 'refresh_failed',
      );

      expect(expiredToken.friendlyMessage, contains('session has expired'));
      expect(invalidToken.friendlyMessage, contains('Invalid authentication'));
      expect(refreshFailed.friendlyMessage, contains('Failed to refresh'));
    });

    test('FrappeConfigurationException should handle config errors', () {
      final exception = FrappeConfigurationException(
        'Invalid base URL',
        field: 'baseUrl',
        suggestion: 'Ensure the URL includes the protocol (https://)',
        code: 'invalid_url',
      );

      expect(exception.message, equals('Invalid base URL'));
      expect(exception.field, equals('baseUrl'));
      expect(exception.suggestion, contains('protocol'));
      expect(exception.friendlyMessage, contains('Configuration error in baseUrl'));
      expect(exception.friendlyMessage, contains('Suggestion:'));
    });

    test('FrappeUserCancelledException should handle user cancellation', () {
      final exception = FrappeUserCancelledException(
        'User cancelled authentication',
      );

      expect(exception.message, equals('User cancelled authentication'));
      expect(exception.code, equals('user_cancelled'));
      expect(exception.friendlyMessage, equals('Authentication was cancelled.'));
    });

    test('FrappePlatformException should handle platform setup errors', () {
      final exception = FrappePlatformException(
        'Android manifest not configured',
        platform: 'android',
        code: 'manifest_error',
        fixSteps: [
          'Add the OAuth redirect activity to AndroidManifest.xml',
          'Ensure the intent filter is correctly configured',
        ],
      );

      expect(exception.message, equals('Android manifest not configured'));
      expect(exception.platform, equals('android'));
      expect(exception.fixSteps, hasLength(2));
      expect(exception.friendlyMessage, contains('Platform setup error on android'));
      expect(exception.friendlyMessage, contains('To fix this issue:'));
      expect(exception.friendlyMessage, contains('1. Add the OAuth'));
    });

    test('FrappeStorageException should handle storage errors', () {
      final exception = FrappeStorageException(
        'Failed to save token',
        operation: 'save',
        code: 'storage_error',
      );

      expect(exception.message, equals('Failed to save token'));
      expect(exception.operation, equals('save'));
      expect(exception.friendlyMessage, contains('Storage error during save'));
    });

    test('should preserve original error context', () {
      final originalError = Exception('Original error');
      final stackTrace = StackTrace.current;

      final exception = FrappeNetworkException(
        'Wrapped error',
        originalError: originalError,
        originalStackTrace: stackTrace,
        context: {'url': 'https://example.com', 'method': 'POST'},
      );

      expect(exception.originalError, equals(originalError));
      expect(exception.originalStackTrace, equals(stackTrace));
      expect(exception.context['url'], equals('https://example.com'));
      expect(exception.context['method'], equals('POST'));
      expect(exception.hasCause, isTrue);
    });

    test('should format toString correctly', () {
      final exception = FrappeNetworkException(
        'Network error',
        code: 'network_timeout',
      );

      final exceptionWithCause = FrappeTokenException(
        'Token error',
        originalError: Exception('Original cause'),
      );

      expect(exception.toString(), contains('FrappeNetworkException: Network error'));
      expect(exception.toString(), contains('(code: network_timeout)'));
      expect(exceptionWithCause.toString(), contains('Caused by:'));
    });

    test('should handle exceptions without optional fields', () {
      final minimalException = FrappeNetworkException('Simple error');

      expect(minimalException.message, equals('Simple error'));
      expect(minimalException.code, isNull);
      expect(minimalException.statusCode, isNull);
      expect(minimalException.originalError, isNull);
      expect(minimalException.hasCause, isFalse);
      expect(minimalException.context, isEmpty);
    });
  });
}
