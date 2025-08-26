import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:frappe_oauth2_flutter_sdk/models/oauth_config.dart';
import 'package:frappe_oauth2_flutter_sdk/services/network_service.dart';
import 'package:frappe_oauth2_flutter_sdk/exceptions/frappe_auth_exception.dart';

import 'network_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('NetworkService', () {
    late MockClient mockClient;
    late OAuthConfig config;
    late NetworkService networkService;

    setUp(() {
      mockClient = MockClient();
      config = const OAuthConfig(
        baseUrl: 'https://test.frappe.cloud',
        clientId: 'test_client',
        redirectScheme: 'testapp',
        enableLogging: false,
      );
      networkService = NetworkService(config: config, client: mockClient);
    });

    tearDown(() {
      networkService.dispose();
    });

    group('GET requests', () {
      test('should make successful GET request', () async {
        // Arrange
        final responseBody = jsonEncode({'message': 'success', 'data': 'test'});
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.fromIterable([utf8.encode(responseBody)]),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        // Act
        final result = await networkService.get('/api/test');

        // Assert
        expect(result['message'], equals('success'));
        expect(result['data'], equals('test'));

        final captured = verify(mockClient.send(captureAny)).captured;
        final request = captured.first as http.BaseRequest;
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/api/test'));
      });

      test('should handle GET request with query parameters', () async {
        // Arrange
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.fromIterable([utf8.encode('{}')]),
            200,
          );
        });

        // Act
        await networkService.get(
          '/api/test',
          queryParams: {'param1': 'value1'},
        );

        // Assert
        final captured = verify(mockClient.send(captureAny)).captured;
        final request = captured.first as http.BaseRequest;
        expect(request.url.queryParameters['param1'], equals('value1'));
      });

      test('should handle GET request with headers', () async {
        // Arrange
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.fromIterable([utf8.encode('{}')]),
            200,
          );
        });

        // Act
        await networkService.get(
          '/api/test',
          headers: {'Authorization': 'Bearer token'},
        );

        // Assert
        final captured = verify(mockClient.send(captureAny)).captured;
        final request = captured.first as http.BaseRequest;
        expect(request.headers['Authorization'], equals('Bearer token'));
      });
    });

    group('POST requests', () {
      test('should make successful POST request with JSON body', () async {
        // Arrange
        final responseBody = jsonEncode({'result': 'created'});
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.fromIterable([utf8.encode(responseBody)]),
            201,
          );
        });

        // Act
        final result = await networkService.post(
          '/api/create',
          body: {'name': 'test', 'value': 123},
        );

        // Assert
        expect(result['result'], equals('created'));

        final captured = verify(mockClient.send(captureAny)).captured;
        final request = captured.first as http.BaseRequest;
        expect(request.method, equals('POST'));
        expect(request.headers['Content-Type'], startsWith('application/json'));
      });

      test('should make POST request with form data', () async {
        // Arrange
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.fromIterable([utf8.encode('{}')]),
            200,
          );
        });

        // Act
        await networkService.post(
          '/api/form',
          formData: {'field1': 'value1', 'field2': 'value2'},
        );

        // Assert
        final captured = verify(mockClient.send(captureAny)).captured;
        final request = captured.first as http.BaseRequest;
        expect(
          request.headers['Content-Type'],
          startsWith('application/x-www-form-urlencoded'),
        );
      });
    });

    group('Error handling', () {
      test('should throw FrappeNetworkException for HTTP errors', () async {
        // Arrange
        final errorBody = jsonEncode({
          'message': 'Not found',
          'code': 'not_found',
        });
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.fromIterable([utf8.encode(errorBody)]),
            404,
          );
        });

        // Act & Assert
        expect(
          () => networkService.get('/api/notfound'),
          throwsA(
            isA<FrappeNetworkException>()
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.message, 'message', 'Not found')
                .having((e) => e.code, 'code', 'not_found'),
          ),
        );
      });

      test('should handle network connection errors', () async {
        // Arrange
        when(
          mockClient.send(any),
        ).thenThrow(const SocketException('Connection refused'));

        // Act & Assert
        expect(
          () => networkService.get('/api/test'),
          throwsA(
            isA<FrappeNetworkException>()
                .having((e) => e.code, 'code', 'connection_failed')
                .having(
                  (e) => e.message,
                  'message',
                  contains('Connection refused'),
                ),
          ),
        );
      });

      test('should handle empty response body', () async {
        // Arrange
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(Stream.fromIterable([]), 200);
        });

        // Act
        final result = await networkService.get('/api/test');

        // Assert
        expect(result, isEmpty);
      });
    });
  });
}
