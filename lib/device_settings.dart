import 'package:shared_preferences/shared_preferences.dart';

class DeviceSettings {
  static const _hostKey = 'device_host';
  static const defaultHost = 'gif-buddy.local';

  static Future<String> getHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_hostKey) ?? defaultHost;
  }

  static Future<void> setHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, host.trim());
  }
}
