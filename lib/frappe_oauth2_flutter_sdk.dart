
import 'frappe_oauth2_flutter_sdk_platform_interface.dart';

class FrappeOauth2FlutterSdk {
  Future<String?> getPlatformVersion() {
    return FrappeOauth2FlutterSdkPlatform.instance.getPlatformVersion();
  }
}
