import 'dart:io';
import 'dart:math';

import 'package:adbready/adbready.dart';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

enum DeviceLanguage {
  caEs('ca-ES', 'Català'),
  csCz('cs-CZ', 'Čeština'),
  daDk('da-DK', 'Dansk'),
  deDe('de-DE', 'Deutsch'),
  enAu('en-AU', 'English (Australia)'),
  enCa('en-CA', 'English (Canada)'),
  enGb('en-GB', 'English (United Kingdom)'),
  enNz('en-NZ', 'English (New Zealand)'),
  enUs('en-US', 'English (United States)'),
  esEs('es-ES', 'Español (España)'),
  esUs('es-US', 'Español (Estados Unidos)'),
  fiPh('fil-PH', 'Filipino'),
  frCa('fr-CA', 'Français (Canada)'),
  frFr('fr-FR', 'Français (France)'),
  hrHr('hr-HR', 'Hrvatski'),
  idId('id-ID', 'Indonesia'),
  itIt('it-IT', 'Italiano'),
  lvLv('lv-LV', 'Latviešu'),
  jaJp('ja-JP', '日本語'),
  ;

  const DeviceLanguage(this.payload, this.content);

  final String payload;
  final String content;
}

enum DeviceSetting {
  displaySettings('am start -a android.settings.DISPLAY_SETTINGS'),
  localeSettings('am start -a android.settings.LOCALE_SETTINGS'),
  tvExternalSourcesActivity('am start -n com.android.tv.settings/.device.apps.specialaccess.ExternalSourcesActivity'),
  tvLanguageActivity('am start -n com.android.tv.settings/.system.LanguageActivity'),
  tvMainSettings('am start -n com.android.tv.settings/com.android.tv.settings.MainSettings'),
  ;

  const DeviceSetting(this.payload);

  final String payload;
}

class InvalidAddressException implements Exception {
  const InvalidAddressException([this.message]);

  final String? message;

  @override
  String toString() {
    String content = 'InvalidAddressException';
    if (message != null) content = '$content: $message';
    return content;
  }
}

class InvalidAndroidException implements Exception {
  const InvalidAndroidException([this.message]);

  final String? message;

  @override
  String toString() {
    String content = 'InvalidAndroidException';
    if (message != null) content = '$content: $message';
    return content;
  }
}

class InvalidConsentException implements Exception {
  const InvalidConsentException([this.message]);

  final String? message;

  @override
  String toString() {
    String content = 'InvalidConsentException';
    if (message != null) content = '$content: $message';
    return content;
  }
}

abstract class Device {
  const Device(this.address, {this.port, this.code});

  /// ...
  final String address;

  /// ...
  final String? port;

  /// ...
  final String? code;

  /// Gather the ip address of the distant device.
  Future<String?> getIpAddr() async {
    for (final adapter in ['eth0', 'wlan0']) {
      final command = ['shell', 'ip -f inet -o addr show $adapter | cut -d \" \" -f 7 | cut -d / -f 1'];
      final address = (await runInvoke(command)).stdout.toString().trim();
      if (address.isNotEmpty) return address;
    }
    return null;
  }

  /// ...
  Future<String> getLocale() async {
    return (await runInvoke(['shell', 'getprop persist.sys.locale'])).stdout.trim();
  }

  /// Gather whether the package is installed on distant device.
  Future<bool> getSeated(String package) async {
    return (await runInvoke(['shell', 'pm path \'$package\''])).stdout.isNotEmpty;
  }

  /// Accord privilege to installed package on distant device.
  Future<void> runAccord(String package, String consent) async {
    await runInvoke(['shell', 'pm grant \'$package\' android.permission.${consent.toUpperCase()}']);
  }

  /// Attach distant device using ip address.
  Future<void> runAttach() async {
    var content = (await runInvoke(['connect', address])).stdout;
    if (content.contains('cann')) {
      throw const InvalidAddressException('Submit address is invalid');
    } else if (content.contains('down')) {
      throw const InvalidAndroidException('Target machine is down');
    } else if (content.contains('empt')) {
      throw const InvalidAddressException('Submit address is empty');
    } else if (content.contains('esol')) {
      throw const InvalidAddressException('Submit address is unreachable');
    } else if (content.contains('fuse')) {
      throw const InvalidAndroidException('Target machine is invalid');
    } else if (content.contains('rout')) {
      throw const InvalidAddressException('Submit address is unreachable');
    } else if (content.contains('fail')) {
      throw const InvalidConsentException('Target machine is waiting for authorization');
    } else {
      content = (await runInvoke(['shell', 'uname'])).stderr;
      if (content.contains('unau')) {
        final android = p.join((await getApplicationSupportDirectory()).path, ".android");
        await runInvoke(['kill-server']);
        if (await Directory(android).exists()) await Directory(android).delete(recursive: true);
        await runAttach();
      }
    }
  }

  /// Bridge distant device using pairing port and code.
  Future<void> runBridge() async {
    final content = (await runInvoke(['pair', '$address:$port', code ?? ''])).stdout;
    if (content.contains('rong')) throw Exception('Specified pairing code is invalid');
  }

  /// Create new folder or file to distant device.
  Future<void> runCreate(String distant) async {
    final command = ['shell', 'mkdir -p "\$(dirname "$distant")" ; touch "$distant"'];
    await runInvoke(command);
  }

  /// Deploy adb to the running device.
  Future<String> runDeploy() async {
    if (Platform.isAndroid) {
      return await Adbready().deploy();
    } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final command = Platform.isWindows ? 'where' : 'which';
      final content = (await Process.run(command, ['adb'])).stdout.trim();
      if (content.isNotEmpty) return content;
      final deposit = (await getTemporaryDirectory()).path;
      const usagent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/500.0 (KHTML, like Gecko) Chrome/100.0.0.0 Safari/500.0';
      final fetcher = Dio()
        ..options.followRedirects = true
        ..options.headers = {'user-agent': usagent};
      final program = File(p.join(deposit, 'platform-tools', 'adb'));
      if (await program.exists() == false) {
        const baseurl = 'https://dl.google.com/android/repository';
        final payload = Platform.isLinux ? 'linux' : (Platform.isMacOS ? 'darwin' : 'windows');
        final address = '$baseurl/platform-tools-latest-$payload.zip';
        final archive = p.join(deposit, p.basename(address));
        await fetcher.download(address, archive);
        await extractFileToDisk(archive, deposit);
      }
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['-R', '+x', program.parent.path]);
      }
      return program.path;
    } else {
      throw UnimplementedError();
    }
  }

  /// ...
  Future<void> runDetach() async {
    await runInvoke(['disconnect', address]);
    await runInvoke(['kill-server']);
  }

  /// Detect the text pattern in picture using OCR and return the center of it.
  Future<Point?> runDetect(File picture, RegExp pattern) async {
    if (!Platform.isAndroid && !Platform.isIOS) throw UnimplementedError();
    final handler = TextRecognizer(script: TextRecognitionScript.latin);
    final results = await handler.processImage(InputImage.fromFile(picture));
    handler.close();
    List members = [];
    for (var block in results.blocks) for (var line in block.lines) for (var element in line.elements) members.add(element);
    final factors = members.where((x) => pattern.hasMatch(x.text));
    if (factors.isEmpty) return null;
    final element = factors.first.boundingBox.center;
    return Point(element.dx.floor(), element.dy.floor());
  }

  /// ...
  Future<void> runEnable(String package, {bool enabled = true}) async {
    final payload = enabled ? 'enable' : 'disable-user --user 0';
    await runInvoke(['shell', 'pm $payload "$package"']);
  }

  /// ...
  Future<void> runEscape() async {
    for (int i = 0; i < 2; i++) await runRepeat('keycode_back', repeats: 8);
    await runRepeat('keycode_wakeup', repeats: 2);
    await Future.delayed(const Duration(seconds: 2));
  }

  /// ...
  Future<void> runExport(String storage, String distant) async {
    await runInvoke(['push', storage, distant]);
  }

  /// ...
  Future<void> runFinish(String package) async {
    if (await getSeated(package)) {
      await runInvoke(['shell', 'sleep 2 ; am force-stop "$package" ; sleep 2']);
    }
  }

  /// TODO: Detect the picture in picture using template matching and return the center of it.
  Future<Point?> runGlance(File factor1, File factor2) async {
    throw UnimplementedError();
  }

  /// ...
  Future<String?> runImport(String distant) async {
    final deposit = (await getTemporaryDirectory()).path;
    final storage = await Directory(p.join(deposit, Uuid().v4())).create(recursive: true);
    final created = p.join(storage.path, p.basename(distant));
    await runInvoke(['pull', distant, created]);
    return (await File(created).exists() || await Directory(created).exists()) ? created : null;
  }

  /// ...
  Future<void> runInsert(String content, {bool cleared = false}) async {
    if (cleared) {
      await runRepeat('keycode_move_end');
      await runRepeat('keycode_del', repeats: 100);
    }
    await runInvoke(['shell', 'input text \'$content\'']);
  }

  /// ...
  Future<ProcessResult> runInvoke(List<String> command) async {
    if (Platform.isAndroid) return await Adbready().invoke(['-s', address, ...command]);
    return await Process.run(await runDeploy(), ['-s', address, ...command]);
  }

  /// ...
  Future<void> runLaunch(String package) async {
    if (await getSeated(package)) {
      await runInvoke(['shell', 'sleep 2 ; monkey -p "$package" 1 ; sleep 2']);
    }
  }

  /// ...
  Future<Point?> runLocate(String pattern) async {
    final element = await runScrape(pattern);
    final content = element?.getAttribute('bounds');
    if (content == null) return null;
    final matches = RegExp('\\d+').allMatches(content);
    return Point(
      (int.parse(matches.elementAt(0).group(0)!) + int.parse(matches.elementAt(2).group(0)!)) / 2,
      (int.parse(matches.elementAt(1).group(0)!) + int.parse(matches.elementAt(3).group(0)!)) / 2,
    );
  }

  /// Lookup for text pattern in picture using OCR.
  Future<Iterable<RegExpMatch>?> runLookup(File picture, RegExp pattern) async {
    if (!Platform.isAndroid && !Platform.isIOS) throw UnimplementedError();
    final handler = TextRecognizer(script: TextRecognitionScript.latin);
    final content = (await handler.processImage(InputImage.fromFile(picture))).text;
    handler.close();
    final matches = pattern.allMatches(content);
    if (matches.isEmpty) return null;
    return matches;
  }

  /// ...
  Future<void> runReboot() async {
    await runInvoke(['shell', 'reboot']);
    await Future.delayed(const Duration(seconds: 4));
    while (true) {
      try {
        await runAttach();
        break;
      } on Exception {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    await Future.delayed(const Duration(seconds: 8));
  }

  /// ...
  Future<void> runRemove(String distant) async {
    await runInvoke(['shell', 'rm -r $distant']);
  }

  /// ...
  Future<String> runRender() async {
    const command = ['shell', 'uiautomator dump'];
    const fetched = '/sdcard/window_dump.xml';
    const package = 'com.android.vending';
    while ((await runInvoke(command)).stderr.trim().isNotEmpty) {
      await runRemove(fetched);
      await runLaunch(package);
      await runInvoke(command);
      await runFinish(package);
    }
    return (await runImport(fetched))!;
  }

  /// ...
  Future<void> runRepeat(String keycode, {int repeats = 1}) async {
    await runInvoke(['shell', "input keyevent \$(printf '${keycode.toUpperCase()} %.0s' \$(seq 1 $repeats))"]);
  }

  /// ...
  Future<void> runReveal(DeviceSetting payload) async {
    await runInvoke(['shell', payload.payload]);
  }

  /// ...
  Future<XmlElement?> runScrape(String pattern) async {
    await runRepeat('keycode_dpad_up', repeats: 100);
    var fetched = await runRender();
    XmlElement? element;
    while (element == null) {
      var scraped = XmlDocument.parse((new File(fetched)).readAsStringSync());
      var results = scraped.xpath(pattern);
      if (results.isNotEmpty) {
        element = results.first as XmlElement?;
        continue;
      }
      element = null;
      await runRepeat('keycode_dpad_down', repeats: 8);
      var stream1 = await File(fetched).readAsString();
      var stream2 = await File(fetched = await runRender()).readAsString();
      if (stream1 == stream2) break;
    }
    return element;
  }

  /// ...
  Future<String?> runScreen({String distant = '/sdcard/screenshot.png'}) async {
    await runInvoke(['shell', 'screencap', '-p', distant]);
    final fetched = await runImport(distant);
    return fetched;
  }

  /// ...
  Future<List<String>?> runSearch(String pattern, {int maximum = 1}) async {
    final results = await runInvoke(['shell', 'find $pattern -maxdepth 0 2>/dev/null | head -$maximum']);
    final content = results.stdout.trim();
    return content.isNotEmpty ? content.split("\n") : null;
  }

  /// ...
  Future<bool> runSelect(String pattern) async {
    final results = await runLocate(pattern);
    if (results == null) return false;
    await runInvoke(['shell', 'input tap ${results.x} ${results.y}']);
    return true;
  }

  /// ...
  Future<void> runUnpack(String archive, String deposit) async {
    if (await File(archive).exists()) {
      final distant = p.join(deposit, p.basename(archive));
      await runInvoke(['shell', 'mkdir -p \'$deposit\'']);
      await runExport(archive, distant);
      await runInvoke(['shell', 'cd \'$deposit\' ; unzip -o \'$distant\'']);
      await runRemove(distant);
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// ...
  Future<void> runUpdate(String package) async {
    if (await File(package).exists()) await runInvoke(['install', '-r', package]);
  }

  /// ...
  Future<void> runVanish(String package) async {
    if (await getSeated(package)) {
      await runFinish(package);
      await runInvoke(['shell', 'pm uninstall \'$package\'']);
    }
  }
}
