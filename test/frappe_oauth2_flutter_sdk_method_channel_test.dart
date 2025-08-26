import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frappe_oauth2_flutter_sdk/frappe_oauth2_flutter_sdk_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFrappeOauth2FlutterSdk platform = MethodChannelFrappeOauth2FlutterSdk();
  const MethodChannel channel = MethodChannel('frappe_oauth2_flutter_sdk');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
