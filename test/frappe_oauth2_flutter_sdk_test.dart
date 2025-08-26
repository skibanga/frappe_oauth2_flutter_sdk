import 'package:flutter_test/flutter_test.dart';
import 'package:frappe_oauth2_flutter_sdk/frappe_oauth2_flutter_sdk.dart';
import 'package:frappe_oauth2_flutter_sdk/frappe_oauth2_flutter_sdk_platform_interface.dart';
import 'package:frappe_oauth2_flutter_sdk/frappe_oauth2_flutter_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFrappeOauth2FlutterSdkPlatform
    with MockPlatformInterfaceMixin
    implements FrappeOauth2FlutterSdkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FrappeOauth2FlutterSdkPlatform initialPlatform = FrappeOauth2FlutterSdkPlatform.instance;

  test('$MethodChannelFrappeOauth2FlutterSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFrappeOauth2FlutterSdk>());
  });

  test('getPlatformVersion', () async {
    FrappeOauth2FlutterSdk frappeOauth2FlutterSdkPlugin = FrappeOauth2FlutterSdk();
    MockFrappeOauth2FlutterSdkPlatform fakePlatform = MockFrappeOauth2FlutterSdkPlatform();
    FrappeOauth2FlutterSdkPlatform.instance = fakePlatform;

    expect(await frappeOauth2FlutterSdkPlugin.getPlatformVersion(), '42');
  });
}
