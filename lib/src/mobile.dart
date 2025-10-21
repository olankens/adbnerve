import 'package:adbnerve/src/device.dart';

class Mobile extends Device {
  const Mobile(super.name, {super.port, super.code});

  Future<void> setLanguage(DeviceLanguage payload) async {
    if (await getLocale() != payload.payload) {
      await runReveal(DeviceSetting.localeSettings);
      await runSelect('//*[@text="${payload.content}"]');
      await runRepeat('keycode_back');
    }
  }
}
