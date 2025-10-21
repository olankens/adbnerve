import 'dart:io';

import 'package:adbnerve/adbnerve.dart';
import 'package:adbnerve/src/device.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

late final String address;
late final Mobile android;

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProviderPlatform();
    android = Mobile(address = '192.168.1.50');
    await android.runAttach();
    await android.runEscape();
  });

  tearDownAll(() async {
    // await android.setLanguage(DeviceLanguage.enUs);
    // await android.runDetach();
  });

  test('setLanguage()', () async {
    final current = await android.getLocale();
    final payload = current == DeviceLanguage.enUs.payload ? DeviceLanguage.frFr : DeviceLanguage.enUs;
    await android.setLanguage(payload);
    expect(await android.getLocale(), payload.payload);
  });
}

class FakePathProviderPlatform extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}
