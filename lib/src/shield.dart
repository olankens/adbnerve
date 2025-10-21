import 'package:adbnerve/src/device.dart';
import 'package:format/format.dart';

enum ShieldBloatwareLevel {
  low('Low'),
  medium('Medium'),
  maximum('Maximum'),
  ;

  const ShieldBloatwareLevel(this.content);

  final String content;
}

enum ShieldResolution {
  p2160DolbyHz23('4K 23.976 Hz Dolby Vision', ['4K', '23.976', true]),
  p2160DolbyHz59('4K 59.940 Hz Dolby Vision', ['4K', '59.940', true]),
  p2160Hdr10Hz23('4K 23.976 Hz HDR10', ['4K', '23.976', false]),
  p2160Hdr10Hz59('4K 59.940 Hz HDR10', ['4K', '59.940', false]),
  p1080DolbyHz23('1080p 23.976 Hz Dolby Vision', ['1080', '23.976', true]),
  p1080DolbyHz59('1080p 59.940 Hz Dolby Vision', ['1080', '59.940', true]),
  p1080Hdr10Hz23('1080p 23.976 Hz HDR10', ['1080', '23.976', false]),
  p1080Hdr10Hz59('1080p 59.940 Hz HDR10', ['1080', '59.940', false]),
  ;

  const ShieldResolution(this.content, this.payload);

  final String content;
  final List payload;
}

enum ShieldUpscaling {
  basic('Basic', ['Basic', '']),
  enhanced('Enhanced', ['Enhanced', '']),
  aiLow('AI Low', ['AI-Enhanced', 'Low']),
  aiMedium('AI Medium', ['AI-Enhanced', 'Medium (default)']),
  aiHigh('AI High', ['AI-Enhanced', 'High']),
  ;

  const ShieldUpscaling(this.content, this.payload);

  final String content;
  final List<String> payload;
}

class Shield extends Device {
  const Shield(super.name, {super.port, super.code});

  Future<void> setBloatware({bool enabled = true}) async {
    final factors = [
      // Nvidia bloatware
      'android.autoinstalls.config.nvidia',
      'com.nvidia.benchmarkblocker',
      'com.nvidia.beyonder.server',
      'com.nvidia.developerwidget',
      'com.nvidia.diagtools',
      'com.nvidia.enhancedlogging',
      'com.nvidia.factorybundling',
      'com.nvidia.feedback',
      'com.nvidia.hotwordsetup',
      'com.nvidia.NvAccSt',
      'com.nvidia.NvCPLUpdater',
      'com.nvidia.ocs',
      'com.nvidia.ota',
      'com.nvidia.shield.appselector',
      'com.nvidia.shield.ask',
      'com.nvidia.shield.nvcustomize',
      'com.nvidia.SHIELD.Platform.Analyser',
      'com.nvidia.shield.registration',
      'com.nvidia.shield.registration',
      'com.nvidia.shield.remote.server',
      'com.nvidia.shield.remotediagnostic',
      'com.nvidia.shieldbeta',
      'com.nvidia.shieldtech.hooks',
      'com.nvidia.shieldtech.proxy',
      'com.nvidia.stats',
      'com.nvidia.tegrazone3',
      // Android bloatware
      'com.android.gallery3d',
      'com.android.dreams.basic',
      'com.android.printspooler',
      'com.android.feedback',
      'com.android.keychain',
      'com.android.cts.priv.ctsshim',
      'com.android.cts.ctsshim',
      'com.android.providers.calendar',
      'com.android.providers.contacts',
      'com.android.se',
      'com.android.vending',
      // Google bloatware
      'com.google.android.speech.pumpkin',
      'com.google.android.tts',
      'com.google.android.videos',
      'com.google.android.tvrecommendations',
      'com.google.android.syncadapters.calendar',
      'com.google.android.backuptransport',
      'com.google.android.partnersetup',
      'com.google.android.inputmethod.korean',
      'com.google.android.inputmethod.pinyin',
      'com.google.android.apps.inputmethod.zhuyin',
      'com.google.android.tv',
      'com.google.android.tv.frameworkpackagestubs',
      'com.google.android.tv.bugreportsender',
      // 'com.google.android.backdrop',
      'com.google.android.leanbacklauncher.recommendations',
      'com.google.android.tvlauncher',
      'com.google.android.feedback',
      'com.google.android.leanbacklauncher',
      // Extra bloatware
      'com.plexapp.mediaserver.smb',
      'com.google.android.play.games',
      'com.netflix.ninja',
      'com.amazon.amazonvideo.livingroom',
      'com.google.android.youtube.tvmusic',
    ];
    // for (final package in factors) await runEnable(package, enabled: enabled);
    final command = enabled ? 'cmd package install-existing' : 'pm uninstall -k --user 0';
    for (final package in factors) {
      await runInvoke(['shell', '$command $package']);
    }
  }

  Future<void> setLanguage(DeviceLanguage payload) async {
    var current = await getLocale();
    if (current.isEmpty) {
      await runReveal(DeviceSetting.tvLanguageActivity);
      await runRepeat('keycode_dpad_up', repeats: 99);
      await runRepeat('keycode_enter');
      await Future.delayed(const Duration(seconds: 5));
    }
    current = await getLocale();
    if (current != payload.payload) {
      await runReveal(DeviceSetting.tvLanguageActivity);
      await runSelect('//*[@text="${payload.content}"]');
      await runRepeat('keycode_back');
    }
  }

  Future<void> setPictureInPicture(String payload, {bool enabled = true}) async {
    await setLanguage(DeviceLanguage.enUs);
    await runReveal(DeviceSetting.tvMainSettings);
    await runSelect('//*[@text="Apps"]');
    await runSelect('//*[@text="Special app access"]');
    await runSelect('//*[@text="Picture-in-picture"]');
    await Future.delayed(const Duration(seconds: 5));
    final pattern = '//*[@text="$payload"]/parent::*/following-sibling::*/node';
    final element = await runScrape(pattern);
    if (element != null) {
      final checked = element.getAttribute('checked') == 'true';
      final correct = (checked && enabled) || (!checked && !enabled);
      if (!correct) await runSelect('//*[@text="$payload"]');
    }
    await runRepeat('keycode_home');
  }

  Future<void> setResolution(ShieldResolution payload) async {
    await setLanguage(DeviceLanguage.enUs);
    await runReveal(DeviceSetting.tvMainSettings);
    await runSelect('//*[@text="Device Preferences"]');
    await runSelect('//*[@text="Display & Sound"]');
    await runSelect('//*[@text="Resolution"]');
    final shaping = "//*[contains(@text, '{}') and contains(@text, '{}') and contains(@text, '{}')]";
    final factors = [payload.payload[0], payload.payload[1], payload.payload[2] ? 'Vision' : 'Hz'];
    final factor1 = shaping.format(factors) + "/parent::*/parent::*/node[1]";
    try {
      final target1 = await runScrape(factor1);
      if (target1 != null) {
        if (target1.getAttribute('checked') == 'true')
          await runRepeat('keycode_back');
        else {
          await runSelect(factor1);
          await runRepeat('keycode_dpad_right', repeats: 5);
          await runRepeat('keycode_dpad_up', repeats: 5);
          await runRepeat('keycode_enter');
        }
        await runSelect('//*[@text="Advanced display settings"]');
        final factor2 = '//*[@text="Match content color space"]/parent::*/following-sibling::*/node';
        final target2 = await runScrape(factor2);
        if (target2 != null) {
          final checked = target2.getAttribute('checked') == 'true';
          final correct = (checked && payload.payload[2]) || (!checked && !payload.payload[2]);
          if (!correct) await runSelect(factor2);
        }
      }
    } catch (_) {}
    await runRepeat('keycode_home');
  }

  Future<void> setScreensaver({bool enabled = true}) async {
    await setLanguage(DeviceLanguage.enUs);
    await runReveal(DeviceSetting.tvMainSettings);
    await runSelect('//*[@text="Device Preferences"]');
    await runSelect('//*[@text="Screen saver"]');
    await runRepeat('keycode_dpad_up', repeats: 10);
    await runRepeat('keycode_enter');
    final payload = enabled ? 'Backdrop' : 'Turn screen off';
    await runSelect('//*[@text="$payload"]');
    await runRepeat('keycode_home');
  }

  Future<void> setUpscaling(ShieldUpscaling payload) async {
    await setLanguage(DeviceLanguage.enUs);
    await runReveal(DeviceSetting.tvMainSettings);
    await runSelect('//*[@text="Device Preferences"]');
    await runSelect('//*[@text="Display & Sound"]');
    await runSelect('//*[@text="AI upscaling"]');
    await runSelect('//*[@text="${payload.payload[0]}"]');
    if (payload.payload[1].isNotEmpty) await runSelect('//*[@text="${payload.payload[1]}"]');
    await runRepeat('keycode_home');
  }
}
