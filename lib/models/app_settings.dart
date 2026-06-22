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
  int clockFaceTheme = 1; // 1=Yellow-Black, 2=Elegance, 3=Blue, 4=Purple, 5=Simple Flat, 6=Simple Classic
  
  // Custom Keyboard Shortcuts (Key Labels)
  String keyLeftPanel = 'B';
  String keyRightPanel = 'E';
  String keyAiChat = 'A';
  String keyPrecisionMode = 'P';
  String keyPlanningMode = 'J';
  
  // UI Toggles
  bool enableAiAssistant = true;
  bool enableLeftPanel = true;
  bool enableRightPanel = true;

  String aiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/openai';
  String aiApiKey = '';
  String aiModel = 'gemini-2.5-flash';
  bool hasCompletedOnboarding = false;
}
