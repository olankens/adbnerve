import 'dart:io';

import 'package:adbnerve/adbnerve.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

late final String address;
late final Shield android;

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProviderPlatform();
    android = Shield(address = '192.168.1.50');
    await android.runAttach();
    await android.runEscape();
  });

  tearDownAll(() async {
    await android.setLanguage(DeviceLanguage.enUs);
    // await android.runDetach();
  });

  test('setLanguage()', () async {
    final current = await android.getLocale();
    final payload = current == DeviceLanguage.enUs.payload ? DeviceLanguage.frFr : DeviceLanguage.enUs;
    await android.setLanguage(payload);
    expect(await android.getLocale(), payload.payload);
  });

  test('setPictureInPicture()', () async {
    await android.setPictureInPicture('Plex', enabled: false);
  });

  test('setResolution()', () async {
    await android.setResolution(ShieldResolution.p1080Hdr10Hz59);
  });

  test('setUpscaling()', () async {
    await android.setUpscaling(ShieldUpscaling.aiHigh);
  });
}

class FakePathProviderPlatform extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}
