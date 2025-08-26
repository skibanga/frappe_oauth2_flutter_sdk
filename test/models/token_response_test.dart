import 'package:flutter_test/flutter_test.dart';
import 'package:frappe_oauth2_flutter_sdk/models/token_response.dart';

void main() {
  group('TokenResponse', () {
    late DateTime testTime;
    late TokenResponse tokenResponse;

    setUp(() {
      testTime = DateTime.now();
      tokenResponse = TokenResponse(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        expiresIn: 3600,
        tokenType: 'Bearer',
        issuedAt: testTime,
        scope: ['all', 'openid'],
      );
    });

    test('should create TokenResponse with all fields', () {
      expect(tokenResponse.accessToken, equals('test_access_token'));
      expect(tokenResponse.refreshToken, equals('test_refresh_token'));
      expect(tokenResponse.expiresIn, equals(3600));
      expect(tokenResponse.tokenType, equals('Bearer'));
      expect(tokenResponse.issuedAt, equals(testTime));
      expect(tokenResponse.scope, equals(['all', 'openid']));
    });

    test('should calculate expiration time correctly', () {
      final expectedExpiration = testTime.add(const Duration(seconds: 3600));
      expect(tokenResponse.expiresAt, equals(expectedExpiration));
    });

    test('should detect if token is expired', () {
      // Create an expired token
      final expiredToken = TokenResponse(
        accessToken: 'expired_token',
        refreshToken: 'refresh_token',
        expiresIn: 3600,
        tokenType: 'Bearer',
        issuedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      expect(expiredToken.isExpired, isTrue);
      expect(tokenResponse.isExpired, isFalse);
    });

    test('should detect if token is expiring soon', () {
      // Create a token expiring in 2 minutes
      final expiringSoonToken = TokenResponse(
        accessToken: 'expiring_token',
        refreshToken: 'refresh_token',
        expiresIn: 120, // 2 minutes
        tokenType: 'Bearer',
        issuedAt: DateTime.now(),
      );

      expect(expiringSoonToken.isExpiringSoon(), isTrue);
      expect(tokenResponse.isExpiringSoon(), isFalse);
    });

    test('should calculate time until expiration', () {
      final timeUntilExpiration = tokenResponse.timeUntilExpiration;
      expect(timeUntilExpiration.inSeconds, greaterThan(3500));
      expect(timeUntilExpiration.inSeconds, lessThanOrEqualTo(3600));
    });

    test('should validate token correctly', () {
      expect(tokenResponse.isValid, isTrue);

      // Test invalid token (empty access token)
      final invalidToken = TokenResponse(
        accessToken: '',
        refreshToken: 'refresh_token',
        expiresIn: 3600,
        tokenType: 'Bearer',
        issuedAt: DateTime.now(),
      );
      expect(invalidToken.isValid, isFalse);
    });

    test('should serialize to and from JSON', () {
      final json = tokenResponse.toJson();
      expect(json['access_token'], equals('test_access_token'));
      expect(json['refresh_token'], equals('test_refresh_token'));
      expect(json['expires_in'], equals(3600));
      expect(json['token_type'], equals('Bearer'));

      final fromJson = TokenResponse.fromJson(json);
      expect(fromJson.accessToken, equals(tokenResponse.accessToken));
      expect(fromJson.refreshToken, equals(tokenResponse.refreshToken));
      expect(fromJson.expiresIn, equals(tokenResponse.expiresIn));
      expect(fromJson.tokenType, equals(tokenResponse.tokenType));
    });

    test('should handle JSON without issued_at field', () {
      final json = {
        'access_token': 'test_token',
        'refresh_token': 'test_refresh',
        'expires_in': 3600,
        'token_type': 'Bearer',
      };

      final fromJson = TokenResponse.fromJson(json);
      expect(fromJson.accessToken, equals('test_token'));
      expect(fromJson.issuedAt, isNotNull);
    });

    test('should handle scope as string', () {
      final json = {
        'access_token': 'test_token',
        'refresh_token': 'test_refresh',
        'expires_in': 3600,
        'token_type': 'Bearer',
        'scope': 'all openid profile',
      };

      final fromJson = TokenResponse.fromJson(json);
      expect(fromJson.scope, equals(['all', 'openid', 'profile']));
    });

    test('should create copy with updated fields', () {
      final copy = tokenResponse.copyWith(
        accessToken: 'new_access_token',
        expiresIn: 7200,
      );

      expect(copy.accessToken, equals('new_access_token'));
      expect(copy.expiresIn, equals(7200));
      expect(copy.refreshToken, equals(tokenResponse.refreshToken));
      expect(copy.tokenType, equals(tokenResponse.tokenType));
    });

    test('should implement equality correctly', () {
      final identical = TokenResponse(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        expiresIn: 3600,
        tokenType: 'Bearer',
        issuedAt: testTime,
      );

      final different = TokenResponse(
        accessToken: 'different_token',
        refreshToken: 'test_refresh_token',
        expiresIn: 3600,
        tokenType: 'Bearer',
        issuedAt: testTime,
      );

      expect(tokenResponse, equals(identical));
      expect(tokenResponse, isNot(equals(different)));
    });
  });
}
