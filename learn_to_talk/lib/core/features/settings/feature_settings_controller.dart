import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller to manage feature settings throughout the app
///
/// This controller provides a centralized way to enable/disable features
/// and remember user preferences across app sessions.
class FeatureSettingsController extends ChangeNotifier {
  static const String _translationEnabledKey = 'translation_enabled';
  static const String _sttEnabledKey = 'stt_enabled';
  static const String _ttsEnabledKey = 'tts_enabled';
  static const String _languageSwitcherEnabledKey = 'language_switcher_enabled';

  /// Whether the translation feature is enabled
  bool _translationEnabled = true;

  /// Whether the speech-to-text feature is enabled
  bool _sttEnabled = true;

  /// Whether the text-to-speech feature is enabled
  bool _ttsEnabled = true;

  /// Whether the language switcher UI is enabled
  bool _languageSwitcherEnabled = true;

  SharedPreferences? _preferences;

  /// Creates a new instance of FeatureSettingsController
  FeatureSettingsController() {
    _loadSettings();
  }

  /// Whether translation features are enabled
  bool get isTranslationEnabled => _translationEnabled;

  /// Whether speech-to-text features are enabled
  bool get isSTTEnabled => _sttEnabled;

  /// Whether text-to-speech features are enabled
  bool get isTTSEnabled => _ttsEnabled;

  /// Whether language switching UI is enabled
  bool get isLanguageSwitcherEnabled => _languageSwitcherEnabled;

  /// Enables or disables the translation feature
  Future<void> setTranslationEnabled(bool enabled) async {
    if (_translationEnabled == enabled) return;

    _translationEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Enables or disables the speech-to-text feature
  Future<void> setSTTEnabled(bool enabled) async {
    if (_sttEnabled == enabled) return;

    _sttEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Enables or disables the text-to-speech feature
  Future<void> setTTSEnabled(bool enabled) async {
    if (_ttsEnabled == enabled) return;

    _ttsEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Enables or disables the language switcher UI
  Future<void> setLanguageSwitcherEnabled(bool enabled) async {
    if (_languageSwitcherEnabled == enabled) return;

    _languageSwitcherEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Loads saved settings from SharedPreferences
  Future<void> _loadSettings() async {
    _preferences = await SharedPreferences.getInstance();

    _translationEnabled = _preferences?.getBool(_translationEnabledKey) ?? true;
    _sttEnabled = _preferences?.getBool(_sttEnabledKey) ?? true;
    _ttsEnabled = _preferences?.getBool(_ttsEnabledKey) ?? true;
    _languageSwitcherEnabled =
        _preferences?.getBool(_languageSwitcherEnabledKey) ?? true;

    notifyListeners();
  }

  /// Saves current settings to SharedPreferences
  Future<void> _saveSettings() async {
    _preferences ??= await SharedPreferences.getInstance();

    await _preferences?.setBool(_translationEnabledKey, _translationEnabled);
    await _preferences?.setBool(_sttEnabledKey, _sttEnabled);
    await _preferences?.setBool(_ttsEnabledKey, _ttsEnabled);
    await _preferences?.setBool(
      _languageSwitcherEnabledKey,
      _languageSwitcherEnabled,
    );
  }
}
