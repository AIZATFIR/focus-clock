import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _keyGeminiApiKey = 'gemini_api_key';
  static const _keyOpenRouterKey = 'openrouter_api_key';
  static const _keyBackendUrl = 'backend_server_url';
  static const _keyVoiceEnabled = 'voice_enabled';

  /// Default local backend server URL for openrouter fallback
  static const defaultBackendUrl = 'http://localhost:3000';

  // ── Gemini API Key (BYOK) ──────────────────────────────────────────────────
  Future<String?> getGeminiApiKey() async {
    return await _storage.read(key: _keyGeminiApiKey);
  }

  Future<void> setGeminiApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _storage.delete(key: _keyGeminiApiKey);
    } else {
      await _storage.write(key: _keyGeminiApiKey, value: key.trim());
    }
  }

  // ── OpenRouter Key (Optional fallback) ────────────────────────────────────
  Future<String?> getOpenRouterKey() async {
    return await _storage.read(key: _keyOpenRouterKey);
  }

  Future<void> setOpenRouterKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _storage.delete(key: _keyOpenRouterKey);
    } else {
      await _storage.write(key: _keyOpenRouterKey, value: key.trim());
    }
  }

  // ── Backend Server URL ─────────────────────────────────────────────────────
  Future<String> getBackendServerUrl() async {
    final url = await _storage.read(key: _keyBackendUrl);
    return (url != null && url.trim().isNotEmpty) ? url.trim() : defaultBackendUrl;
  }

  Future<void> setBackendServerUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _storage.delete(key: _keyBackendUrl);
    } else {
      await _storage.write(key: _keyBackendUrl, value: url.trim());
    }
  }

  // ── Voice Output Enabled ───────────────────────────────────────────────────
  Future<bool> isVoiceEnabled() async {
    final val = await _storage.read(key: _keyVoiceEnabled);
    return val != 'false'; // Enabled by default
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    await _storage.write(key: _keyVoiceEnabled, value: enabled.toString());
  }

  /// Clear all stored secure credentials
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
