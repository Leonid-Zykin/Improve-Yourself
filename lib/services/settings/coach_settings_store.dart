import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted OpenRouter coach settings (API key + model id).
///
/// Prefers [FlutterSecureStorage] (Keystore / Keychain / libsecret).
/// Falls back to [SharedPreferences] if the secret service is unavailable
/// (common on some Linux desktops). Linux builds need `libsecret-1-dev`.
class CoachSettings {
  const CoachSettings({
    this.apiKey,
    this.modelId = CoachSettingsStore.defaultModelId,
  });

  final String? apiKey;
  final String modelId;

  bool get hasApiKey => apiKey != null && apiKey!.trim().isNotEmpty;
}

class CoachSettingsStore {
  CoachSettingsStore({
    FlutterSecureStorage? storage,
    SharedPreferences? prefs,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _prefsOverride = prefs;

  static const defaultModelId = 'openrouter/free';

  static const _keyApi = 'openrouter_api_key';
  static const _keyModel = 'openrouter_model_id';

  final FlutterSecureStorage _storage;
  final SharedPreferences? _prefsOverride;
  bool _usePrefsFallback = false;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<CoachSettings> load() async {
    if (!_usePrefsFallback) {
      try {
        final key = await _storage.read(key: _keyApi);
        final model = await _storage.read(key: _keyModel);
        return _fromRaw(key, model);
      } on Object {
        _usePrefsFallback = true;
      }
    }
    return _loadFromPrefs();
  }

  Future<void> save({required String? apiKey, required String modelId}) async {
    final trimmedKey = apiKey?.trim();
    final trimmedModel = modelId.trim();
    final modelValue =
        trimmedModel.isEmpty ? defaultModelId : trimmedModel;

    if (!_usePrefsFallback) {
      try {
        if (trimmedKey == null || trimmedKey.isEmpty) {
          await _storage.delete(key: _keyApi);
        } else {
          await _storage.write(key: _keyApi, value: trimmedKey);
        }
        await _storage.write(key: _keyModel, value: modelValue);
        return;
      } on Object {
        _usePrefsFallback = true;
      }
    }
    await _saveToPrefs(
      apiKey: (trimmedKey == null || trimmedKey.isEmpty) ? null : trimmedKey,
      modelId: modelValue,
    );
  }

  Future<void> clearApiKey() async {
    if (!_usePrefsFallback) {
      try {
        await _storage.delete(key: _keyApi);
        return;
      } on Object {
        _usePrefsFallback = true;
      }
    }
    final prefs = await _prefs();
    await prefs.remove(_keyApi);
  }

  Future<CoachSettings> _loadFromPrefs() async {
    final prefs = await _prefs();
    return _fromRaw(prefs.getString(_keyApi), prefs.getString(_keyModel));
  }

  Future<void> _saveToPrefs({
    required String? apiKey,
    required String modelId,
  }) async {
    final prefs = await _prefs();
    if (apiKey == null) {
      await prefs.remove(_keyApi);
    } else {
      await prefs.setString(_keyApi, apiKey);
    }
    await prefs.setString(_keyModel, modelId);
  }

  CoachSettings _fromRaw(String? key, String? model) {
    final trimmedKey = key?.trim();
    final trimmedModel = model?.trim();
    return CoachSettings(
      apiKey: (trimmedKey == null || trimmedKey.isEmpty) ? null : trimmedKey,
      modelId: (trimmedModel == null || trimmedModel.isEmpty)
          ? defaultModelId
          : trimmedModel,
    );
  }
}
