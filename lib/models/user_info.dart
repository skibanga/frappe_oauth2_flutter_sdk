import 'package:json_annotation/json_annotation.dart';

part 'user_info.g.dart';

/// Represents user information retrieved from Frappe OAuth2 user info endpoint
/// 
/// Contains user profile data including ID, email, name, and additional
/// Frappe-specific user information.
@JsonSerializable()
class UserInfo {
  /// Unique user identifier in Frappe
  @JsonKey(name: 'sub')
  final String userId;

  /// User's email address
  final String email;

  /// User's full name
  @JsonKey(name: 'name')
  final String fullName;

  /// User's first name (if available)
  @JsonKey(name: 'given_name')
  final String? firstName;

  /// User's last name (if available)
  @JsonKey(name: 'family_name')
  final String? lastName;

  /// User's profile picture URL (if available)
  @JsonKey(name: 'picture')
  final String? profileImage;

  /// User's preferred username
  @JsonKey(name: 'preferred_username')
  final String? username;

  /// Whether the user's email is verified
  @JsonKey(name: 'email_verified')
  final bool? emailVerified;

  /// User's locale/language preference
  final String? locale;

  /// User's timezone
  final String? zoneinfo;

  /// Timestamp when the user info was last updated
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Additional user data that might be specific to the Frappe instance
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Map<String, dynamic> additionalData;

  const UserInfo({
    required this.userId,
    required this.email,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.username,
    this.emailVerified,
    this.locale,
    this.zoneinfo,
    this.updatedAt,
    this.additionalData = const {},
  });

  /// Creates a UserInfo from JSON response
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    // Extract known fields
    final knownFields = {
      'sub', 'email', 'name', 'given_name', 'family_name', 
      'picture', 'preferred_username', 'email_verified', 
      'locale', 'zoneinfo', 'updated_at'
    };
    
    // Collect additional data
    final additionalData = <String, dynamic>{};
    for (final entry in json.entries) {
      if (!knownFields.contains(entry.key)) {
        additionalData[entry.key] = entry.value;
      }
    }

    return UserInfo(
      userId: json['sub'] as String,
      email: json['email'] as String,
      fullName: json['name'] as String,
      firstName: json['given_name'] as String?,
      lastName: json['family_name'] as String?,
      profileImage: json['picture'] as String?,
      username: json['preferred_username'] as String?,
      emailVerified: json['email_verified'] as bool?,
      locale: json['locale'] as String?,
      zoneinfo: json['zoneinfo'] as String?,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      additionalData: additionalData,
    );
  }

  /// Converts UserInfo to JSON
  Map<String, dynamic> toJson() {
    final json = _$UserInfoToJson(this);
    // Add additional data to the JSON
    json.addAll(additionalData);
    return json;
  }

  /// Gets the user's display name (full name or username or email)
  String get displayName {
    if (fullName.isNotEmpty) return fullName;
    if (username != null && username!.isNotEmpty) return username!;
    return email;
  }

  /// Gets the user's initials for avatar display
  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    
    final nameParts = fullName.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    
    if (fullName.isNotEmpty) {
      return fullName[0].toUpperCase();
    }
    
    return email[0].toUpperCase();
  }

  /// Checks if the user has a profile image
  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;

  /// Creates a copy of this UserInfo with updated fields
  UserInfo copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? firstName,
    String? lastName,
    String? profileImage,
    String? username,
    bool? emailVerified,
    String? locale,
    String? zoneinfo,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalData,
  }) {
    return UserInfo(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      username: username ?? this.username,
      emailVerified: emailVerified ?? this.emailVerified,
      locale: locale ?? this.locale,
      zoneinfo: zoneinfo ?? this.zoneinfo,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserInfo &&
        other.userId == userId &&
        other.email == email &&
        other.fullName == fullName;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ email.hashCode ^ fullName.hashCode;
  }

  @override
  String toString() {
    return 'UserInfo(userId: $userId, email: $email, fullName: $fullName)';
  }
}
