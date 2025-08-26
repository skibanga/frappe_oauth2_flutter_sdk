import 'package:frappe_oauth2_flutter_sdk/exceptions/frappe_auth_exception.dart';
import 'package:frappe_oauth2_flutter_sdk/models/token_response.dart';
import 'package:frappe_oauth2_flutter_sdk/models/user_info.dart';

/// Represents the result of an authentication operation
/// 
/// Contains either successful authentication data (tokens and user info)
/// or error information if the authentication failed.
class AuthResult {
  /// Whether the authentication was successful
  final bool success;

  /// User information (only available on success)
  final UserInfo? userInfo;

  /// Token response (only available on success)
  final TokenResponse? tokens;

  /// Error information (only available on failure)
  final FrappeAuthException? error;

  /// Additional metadata about the authentication process
  final Map<String, dynamic> metadata;

  const AuthResult._({
    required this.success,
    this.userInfo,
    this.tokens,
    this.error,
    this.metadata = const {},
  });

  /// Creates a successful authentication result
  factory AuthResult.success({
    required UserInfo userInfo,
    required TokenResponse tokens,
    Map<String, dynamic> metadata = const {},
  }) {
    return AuthResult._(
      success: true,
      userInfo: userInfo,
      tokens: tokens,
      metadata: metadata,
    );
  }

  /// Creates a failed authentication result
  factory AuthResult.failure({
    required FrappeAuthException error,
    Map<String, dynamic> metadata = const {},
  }) {
    return AuthResult._(
      success: false,
      error: error,
      metadata: metadata,
    );
  }

  /// Creates a cancelled authentication result (user cancelled the flow)
  factory AuthResult.cancelled({
    String message = 'Authentication was cancelled by the user',
    Map<String, dynamic> metadata = const {},
  }) {
    return AuthResult._(
      success: false,
      error: FrappeUserCancelledException(message),
      metadata: metadata,
    );
  }

  /// Whether the authentication failed
  bool get isFailure => !success;

  /// Whether the authentication was cancelled by the user
  bool get isCancelled => error is FrappeUserCancelledException;

  /// Whether the authentication failed due to a network error
  bool get isNetworkError => error is FrappeNetworkException;

  /// Whether the authentication failed due to invalid tokens
  bool get isTokenError => error is FrappeTokenException;

  /// Whether the authentication failed due to configuration issues
  bool get isConfigurationError => error is FrappeConfigurationException;

  /// Gets the error message if authentication failed
  String? get errorMessage => error?.message;

  /// Gets the error code if authentication failed
  String? get errorCode => error?.code;

  /// Gets a user-friendly error message
  String get friendlyErrorMessage {
    if (success) return 'Authentication successful';
    
    if (isCancelled) {
      return 'Authentication was cancelled';
    }
    
    if (isNetworkError) {
      return 'Network error occurred. Please check your connection and try again.';
    }
    
    if (isTokenError) {
      return 'Authentication failed. Please try logging in again.';
    }
    
    if (isConfigurationError) {
      return 'Configuration error. Please contact support.';
    }
    
    return error?.message ?? 'An unknown error occurred';
  }

  /// Executes a callback if authentication was successful
  T? onSuccess<T>(T Function(UserInfo userInfo, TokenResponse tokens) callback) {
    if (success && userInfo != null && tokens != null) {
      return callback(userInfo!, tokens!);
    }
    return null;
  }

  /// Executes a callback if authentication failed
  T? onFailure<T>(T Function(FrappeAuthException error) callback) {
    if (!success && error != null) {
      return callback(error!);
    }
    return null;
  }

  /// Executes appropriate callback based on result
  T when<T>({
    required T Function(UserInfo userInfo, TokenResponse tokens) success,
    required T Function(FrappeAuthException error) failure,
  }) {
    if (this.success && userInfo != null && tokens != null) {
      return success(userInfo!, tokens!);
    } else if (error != null) {
      return failure(error!);
    } else {
      throw StateError('AuthResult is in an invalid state');
    }
  }

  /// Creates a copy of this AuthResult with updated metadata
  AuthResult copyWith({
    Map<String, dynamic>? metadata,
  }) {
    if (success) {
      return AuthResult.success(
        userInfo: userInfo!,
        tokens: tokens!,
        metadata: metadata ?? this.metadata,
      );
    } else {
      return AuthResult.failure(
        error: error!,
        metadata: metadata ?? this.metadata,
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResult &&
        other.success == success &&
        other.userInfo == userInfo &&
        other.tokens == tokens &&
        other.error == error;
  }

  @override
  int get hashCode {
    return success.hashCode ^
        userInfo.hashCode ^
        tokens.hashCode ^
        error.hashCode;
  }

  @override
  String toString() {
    if (success) {
      return 'AuthResult.success(user: ${userInfo?.displayName})';
    } else {
      return 'AuthResult.failure(error: ${error?.message})';
    }
  }
}
