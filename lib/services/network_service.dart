import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:frappe_oauth2_flutter_sdk/exceptions/frappe_auth_exception.dart';
import 'package:frappe_oauth2_flutter_sdk/models/oauth_config.dart';

/// HTTP client wrapper for Frappe API calls with proper error handling,
/// request/response logging, and retry logic.
class NetworkService {
  final OAuthConfig config;
  final http.Client _client;

  NetworkService({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  /// Makes a GET request to the specified endpoint
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final request = http.Request('GET', uri);

    if (headers != null) {
      request.headers.addAll(headers);
    }

    return _executeRequest(request);
  }

  /// Makes a POST request to the specified endpoint
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, String>? formData,
  }) async {
    final uri = _buildUri(endpoint);
    final request = http.Request('POST', uri);

    // Set default headers
    request.headers.addAll({
      'Content-Type': formData != null
          ? 'application/x-www-form-urlencoded'
          : 'application/json',
    });

    if (headers != null) {
      request.headers.addAll(headers);
    }

    // Set body
    if (formData != null) {
      request.bodyFields = formData;
    } else if (body != null) {
      request.body = jsonEncode(body);
    }

    return _executeRequest(request);
  }

  /// Makes a PUT request to the specified endpoint
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(endpoint);
    final request = http.Request('PUT', uri);

    request.headers.addAll({'Content-Type': 'application/json'});

    if (headers != null) {
      request.headers.addAll(headers);
    }

    if (body != null) {
      request.body = jsonEncode(body);
    }

    return _executeRequest(request);
  }

  /// Makes a DELETE request to the specified endpoint
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    final request = http.Request('DELETE', uri);

    if (headers != null) {
      request.headers.addAll(headers);
    }

    return _executeRequest(request);
  }

  /// Executes the HTTP request with error handling and logging
  Future<Map<String, dynamic>> _executeRequest(http.Request request) async {
    try {
      _logRequest(request);

      final streamedResponse = await _client
          .send(request)
          .timeout(config.networkTimeout);

      final response = await http.Response.fromStream(streamedResponse);

      _logResponse(response);

      return _handleResponse(response);
    } on SocketException catch (e, stackTrace) {
      throw FrappeNetworkException(
        'Network connection failed: ${e.message}',
        code: 'connection_failed',
        originalError: e,
        originalStackTrace: stackTrace,
      );
    } on HttpException catch (e, stackTrace) {
      throw FrappeNetworkException(
        'HTTP error: ${e.message}',
        code: 'http_error',
        originalError: e,
        originalStackTrace: stackTrace,
      );
    } on FormatException catch (e, stackTrace) {
      throw FrappeNetworkException(
        'Invalid response format: ${e.message}',
        code: 'invalid_format',
        originalError: e,
        originalStackTrace: stackTrace,
      );
    } on FrappeNetworkException {
      // Re-throw our own exceptions without wrapping
      rethrow;
    } catch (e, stackTrace) {
      if (e.toString().toLowerCase().contains('timeout')) {
        throw FrappeNetworkException(
          'Request timeout after ${config.networkTimeout.inSeconds} seconds',
          code: 'timeout',
          originalError: e,
          originalStackTrace: stackTrace,
        );
      }

      throw FrappeNetworkException(
        'Network request failed: $e',
        code: 'unknown_error',
        originalError: e,
        originalStackTrace: stackTrace,
      );
    }
  }

  /// Handles the HTTP response and converts it to a Map
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    // Handle successful responses
    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) {
        return <String, dynamic>{};
      }

      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {'data': decoded};
        }
      } catch (e) {
        throw FrappeNetworkException(
          'Failed to parse response JSON: $e',
          code: 'json_parse_error',
          statusCode: statusCode,
          responseBody: body,
        );
      }
    }

    // Handle error responses
    String errorMessage = 'HTTP $statusCode';
    String? errorCode;

    try {
      final errorData = jsonDecode(body);
      if (errorData is Map<String, dynamic>) {
        errorMessage =
            errorData['message'] ??
            errorData['error'] ??
            errorData['detail'] ??
            errorMessage;
        errorCode = errorData['code']?.toString();
      }
    } catch (_) {
      // If we can't parse the error response, use the raw body
      if (body.isNotEmpty) {
        errorMessage = body;
      }
    }

    throw FrappeNetworkException(
      errorMessage,
      code: errorCode ?? 'http_$statusCode',
      statusCode: statusCode,
      responseBody: body,
    );
  }

  /// Builds a URI from endpoint and query parameters
  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final baseUri = Uri.parse(config.baseUrl);
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';

    return baseUri.replace(
      path: baseUri.path + path,
      queryParameters: queryParams,
    );
  }

  /// Logs the outgoing request (if logging is enabled)
  void _logRequest(http.Request request) {
    if (!config.enableLogging) return;

    print('🌐 HTTP ${request.method} ${request.url}');
    if (request.headers.isNotEmpty) {
      print('📤 Headers: ${_sanitizeHeaders(request.headers)}');
    }
    if (request.body.isNotEmpty) {
      print('📤 Body: ${_sanitizeBody(request.body)}');
    }
  }

  /// Logs the incoming response (if logging is enabled)
  void _logResponse(http.Response response) {
    if (!config.enableLogging) return;

    final statusEmoji = response.statusCode < 400 ? '✅' : '❌';
    print('$statusEmoji HTTP ${response.statusCode} ${response.reasonPhrase}');

    if (response.headers.isNotEmpty) {
      print('📥 Headers: ${response.headers}');
    }

    if (response.body.isNotEmpty) {
      final body = response.body.length > 1000
          ? '${response.body.substring(0, 1000)}...'
          : response.body;
      print('📥 Body: $body');
    }
  }

  /// Sanitizes headers for logging (removes sensitive information)
  Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    final sanitized = Map<String, String>.from(headers);

    // Remove or mask sensitive headers
    const sensitiveHeaders = ['authorization', 'cookie', 'x-api-key'];
    for (final header in sensitiveHeaders) {
      if (sanitized.containsKey(header)) {
        sanitized[header] = '***';
      }
    }

    return sanitized;
  }

  /// Sanitizes request body for logging (removes sensitive information)
  String _sanitizeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final sanitized = Map<String, dynamic>.from(decoded);

        // Remove or mask sensitive fields
        const sensitiveFields = ['password', 'token', 'secret', 'key'];
        for (final field in sensitiveFields) {
          if (sanitized.containsKey(field)) {
            sanitized[field] = '***';
          }
        }

        return jsonEncode(sanitized);
      }
    } catch (_) {
      // If we can't parse as JSON, return as-is (might be form data)
    }

    return body;
  }

  /// Disposes of the HTTP client
  void dispose() {
    _client.close();
  }
}
