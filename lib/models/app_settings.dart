import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = 0;

  bool is24h = false;
  int notifLeadMinutes = 1;
  String themeMode = 'dark'; // 'dark' | 'light' | 'system'
  bool trueBlack = false; // AMOLED: pure black bg when dark theme active
  int clockHandsMode = 1; // 1=single precision, 2=hour+min, 3=hour+min+sec
  bool showMinuteLabels = false;
  String aiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/openai';
  String aiApiKey = '';
  String aiModel = 'gemini-2.5-flash';
}
