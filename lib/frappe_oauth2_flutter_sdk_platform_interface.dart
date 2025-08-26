import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'frappe_oauth2_flutter_sdk_method_channel.dart';

abstract class FrappeOauth2FlutterSdkPlatform extends PlatformInterface {
  /// Constructs a FrappeOauth2FlutterSdkPlatform.
  FrappeOauth2FlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static FrappeOauth2FlutterSdkPlatform _instance = MethodChannelFrappeOauth2FlutterSdk();

  /// The default instance of [FrappeOauth2FlutterSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelFrappeOauth2FlutterSdk].
  static FrappeOauth2FlutterSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FrappeOauth2FlutterSdkPlatform] when
  /// they register themselves.
  static set instance(FrappeOauth2FlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
