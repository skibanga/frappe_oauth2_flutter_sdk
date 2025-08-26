/// Base class for all Frappe OAuth2 authentication exceptions
/// 
/// Provides a consistent error handling interface with error codes,
/// messages, and original error context preservation.
abstract class FrappeAuthException implements Exception {
  /// Human-readable error message
  final String message;

  /// Machine-readable error code for programmatic handling
  final String? code;

  /// Original error that caused this exception (if any)
  final dynamic originalError;

  /// Stack trace from the original error (if any)
  final StackTrace? originalStackTrace;

  /// Additional context data about the error
  final Map<String, dynamic> context;

  const FrappeAuthException(
    this.message, {
    this.code,
    this.originalError,
    this.originalStackTrace,
    this.context = const {},
  });

  /// Creates a user-friendly error message
  String get friendlyMessage => message;

  /// Whether this exception was caused by another exception
  bool get hasCause => originalError != null;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (code != null) {
      buffer.write(' (code: $code)');
    }
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    return buffer.toString();
  }
}

/// Exception thrown when network operations fail
class FrappeNetworkException extends FrappeAuthException {
  /// HTTP status code (if applicable)
  final int? statusCode;

  /// Response body (if available)
  final String? responseBody;

  const FrappeNetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.originalStackTrace,
    super.context,
    this.statusCode,
    this.responseBody,
  });

  /// Whether this is a client error (4xx status code)
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// Whether this is a server error (5xx status code)
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Whether this is a timeout error
  bool get isTimeout => code == 'timeout' || message.toLowerCase().contains('timeout');

  @override
  String get friendlyMessage {
    if (isTimeout) {
      return 'Request timed out. Please check your connection and try again.';
    }
    if (isClientError) {
      return 'Invalid request. Please check your configuration.';
    }
    if (isServerError) {
      return 'Server error occurred. Please try again later.';
    }
    return 'Network error occurred. Please check your connection.';
  }
}

/// Exception thrown when token operations fail
class FrappeTokenException extends FrappeAuthException {
  /// The token that caused the error (if safe to include)
  final String? tokenHint;

  const FrappeTokenException(
    super.message, {
    super.code,
    super.originalError,
    super.originalStackTrace,
    super.context,
    this.tokenHint,
  });

  @override
  String get friendlyMessage {
    if (code == 'expired_token') {
      return 'Your session has expired. Please log in again.';
    }
    if (code == 'invalid_token') {
      return 'Invalid authentication. Please log in again.';
    }
    if (code == 'refresh_failed') {
      return 'Failed to refresh session. Please log in again.';
    }
    return 'Authentication error occurred. Please log in again.';
  }
}

/// Exception thrown when configuration is invalid
class FrappeConfigurationException extends FrappeAuthException {
  /// The configuration field that caused the error
  final String? field;

  /// Suggested fix for the configuration issue
  final String? suggestion;

  const FrappeConfigurationException(
    super.message, {
    super.code,
    super.originalError,
    super.originalStackTrace,
    super.context,
    this.field,
    this.suggestion,
  });

  @override
  String get friendlyMessage {
    final buffer = StringBuffer('Configuration error');
    if (field != null) {
      buffer.write(' in $field');
    }
    buffer.write(': $message');
    if (suggestion != null) {
      buffer.write('\nSuggestion: $suggestion');
    }
    return buffer.toString();
  }
}

/// Exception thrown when user cancels the authentication flow
class FrappeUserCancelledException extends FrappeAuthException {
  const FrappeUserCancelledException(
    super.message, {
    super.code = 'user_cancelled',
    super.originalError,
    super.originalStackTrace,
    super.context,
  });

  @override
  String get friendlyMessage => 'Authentication was cancelled.';
}

/// Exception thrown when platform setup is invalid or incomplete
class FrappePlatformException extends FrappeAuthException {
  /// The platform that has the issue (android, ios, web, etc.)
  final String? platform;

  /// Steps to fix the platform issue
  final List<String> fixSteps;

  const FrappePlatformException(
    super.message, {
    super.code,
    super.originalError,
    super.originalStackTrace,
    super.context,
    this.platform,
    this.fixSteps = const [],
  });

  @override
  String get friendlyMessage {
    final buffer = StringBuffer('Platform setup error');
    if (platform != null) {
      buffer.write(' on $platform');
    }
    buffer.write(': $message');
    if (fixSteps.isNotEmpty) {
      buffer.write('\n\nTo fix this issue:');
      for (int i = 0; i < fixSteps.length; i++) {
        buffer.write('\n${i + 1}. ${fixSteps[i]}');
      }
    }
    return buffer.toString();
  }
}

/// Exception thrown when storage operations fail
class FrappeStorageException extends FrappeAuthException {
  /// The storage operation that failed
  final String? operation;

  const FrappeStorageException(
    super.message, {
    super.code,
    super.originalError,
    super.originalStackTrace,
    super.context,
    this.operation,
  });

  @override
  String get friendlyMessage {
    if (operation != null) {
      return 'Storage error during $operation: $message';
    }
    return 'Storage error: $message';
  }
}
