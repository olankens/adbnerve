import 'dart:io';

import 'package:adbnerve/adbnerve.dart';
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
    // await android.runDetach();
  });

  test('getLocale()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('getSeated()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runAccord()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runAttach()', () async {
    await android.runAttach();
  });

  test('runBridge()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runCreate()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runDeploy()', () async {
    final program = await android.runDeploy();
    final content = (await Process.run(program, ['--version'])).stdout;
    expect(content.isEmpty, false);
  });

  test('runDetach()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runEnable()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runEscape()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runExport()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runFinish()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runImport()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runInsert()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runInvoke()', () async {
    expect((await android.runInvoke(['shell', 'echo dummy'])).stdout.trim(), 'dummy');
  });

  test('runLaunch()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runLocate()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runReboot()', () async {
    await android.runReboot();
    expect((await android.runInvoke(['shell', 'echo dummy'])).stdout.trim(), 'dummy');
  });

  test('runRemove()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runRender()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runRepeat()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runScrape()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runScreen()', () async {
    final fetched = File((await android.runScreen())!);
    expect(fetched.lengthSync() > 0, true);
  });

  test('runSearch()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runSelect()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runUnpack()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runUpdate()', () async {
    // ...
  }, skip: 'not implemented yet');

  test('runVanish()', () async {
    // ...
  }, skip: 'not implemented yet');
}

class FakePathProviderPlatform extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}
