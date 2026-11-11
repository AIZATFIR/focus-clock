import 'package:shared_preferences/shared_preferences.dart';

abstract interface class FallbackStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SharedPreferencesFallbackStorage implements FallbackStorage {
  SharedPreferencesFallbackStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}
