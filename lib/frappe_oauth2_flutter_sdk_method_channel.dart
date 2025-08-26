import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'frappe_oauth2_flutter_sdk_platform_interface.dart';

/// An implementation of [FrappeOauth2FlutterSdkPlatform] that uses method channels.
class MethodChannelFrappeOauth2FlutterSdk extends FrappeOauth2FlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('frappe_oauth2_flutter_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
