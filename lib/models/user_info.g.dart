// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
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
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
  'sub': instance.userId,
  'email': instance.email,
  'name': instance.fullName,
  'given_name': instance.firstName,
  'family_name': instance.lastName,
  'picture': instance.profileImage,
  'preferred_username': instance.username,
  'email_verified': instance.emailVerified,
  'locale': instance.locale,
  'zoneinfo': instance.zoneinfo,
  'updated_at': instance.updatedAt?.toIso8601String(),
};
