// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oauth_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OAuthConfig _$OAuthConfigFromJson(Map<String, dynamic> json) => OAuthConfig(
  baseUrl: json['baseUrl'] as String,
  clientId: json['clientId'] as String,
  redirectScheme: json['redirectScheme'] as String,
  scopes:
      (json['scopes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const ['all', 'openid'],
  tokenRefreshThreshold: json['tokenRefreshThreshold'] == null
      ? const Duration(minutes: 5)
      : OAuthConfig._durationFromJson(
          (json['tokenRefreshThreshold'] as num).toInt(),
        ),
  autoRefresh: json['autoRefresh'] as bool? ?? true,
  storageType:
      $enumDecodeNullable(_$StorageTypeEnumMap, json['storageType']) ??
      StorageType.secure,
  customAuthorizationEndpoint: json['customAuthorizationEndpoint'] as String?,
  customTokenEndpoint: json['customTokenEndpoint'] as String?,
  customUserInfoEndpoint: json['customUserInfoEndpoint'] as String?,
  additionalAuthParams:
      (json['additionalAuthParams'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  networkTimeout: json['networkTimeout'] == null
      ? const Duration(seconds: 30)
      : OAuthConfig._durationFromJson((json['networkTimeout'] as num).toInt()),
  enableLogging: json['enableLogging'] as bool? ?? false,
);

Map<String, dynamic> _$OAuthConfigToJson(OAuthConfig instance) =>
    <String, dynamic>{
      'baseUrl': instance.baseUrl,
      'clientId': instance.clientId,
      'redirectScheme': instance.redirectScheme,
      'scopes': instance.scopes,
      'tokenRefreshThreshold': OAuthConfig._durationToJson(
        instance.tokenRefreshThreshold,
      ),
      'autoRefresh': instance.autoRefresh,
      'storageType': _$StorageTypeEnumMap[instance.storageType]!,
      'customAuthorizationEndpoint': instance.customAuthorizationEndpoint,
      'customTokenEndpoint': instance.customTokenEndpoint,
      'customUserInfoEndpoint': instance.customUserInfoEndpoint,
      'additionalAuthParams': instance.additionalAuthParams,
      'networkTimeout': OAuthConfig._durationToJson(instance.networkTimeout),
      'enableLogging': instance.enableLogging,
    };

const _$StorageTypeEnumMap = {
  StorageType.secure: 'secure',
  StorageType.sharedPreferences: 'sharedPreferences',
  StorageType.hive: 'hive',
};
