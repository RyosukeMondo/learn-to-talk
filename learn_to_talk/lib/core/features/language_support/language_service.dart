import 'package:flutter/material.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage language settings throughout the app
///
/// This service provides a centralized way to manage selected languages,
/// remember user preferences, and notify widgets when language settings change.
class LanguageService extends ChangeNotifier {
  static const String _sourceLanguageKey = 'source_language_code';
  static const String _targetLanguageKey = 'target_language_code';

  /// List of available languages in the app
  final List<Language> availableLanguages;

  /// Current source language code
  String _sourceLanguageCode;

  /// Current target language code
  String _targetLanguageCode;

  /// Whether source and target languages can be the same
  final bool allowSameLanguage;

  /// SharedPreferences instance for persisting language preferences
  SharedPreferences? _preferences;

  /// Creates a new LanguageService
  ///
  /// [availableLanguages] is the list of supported languages
  /// [initialSourceLanguageCode] is the default source language code
  /// [initialTargetLanguageCode] is the default target language code
  /// [allowSameLanguage] determines if source and target can be identical
  LanguageService({
    required this.availableLanguages,
    required String initialSourceLanguageCode,
    required String initialTargetLanguageCode,
    this.allowSameLanguage = false,
  }) : _sourceLanguageCode = initialSourceLanguageCode,
       _targetLanguageCode = initialTargetLanguageCode {
    _loadPreferences();
  }

  /// Current source language code
  String get sourceLanguageCode => _sourceLanguageCode;

  /// Current target language code
  String get targetLanguageCode => _targetLanguageCode;

  /// Gets the Language object for the current source language
  Language get sourceLanguage {
    return availableLanguages.firstWhere(
      (lang) => lang.languageCode == _sourceLanguageCode,
      orElse: () => availableLanguages.first,
    );
  }

  /// Gets the Language object for the current target language
  Language get targetLanguage {
    return availableLanguages.firstWhere(
      (lang) => lang.languageCode == _targetLanguageCode,
      orElse: () => availableLanguages.last,
    );
  }

  /// Gets a filtered list of target languages based on current source language
  List<Language> get availableTargetLanguages {
    if (allowSameLanguage) {
      return availableLanguages;
    }
    return availableLanguages
        .where((lang) => lang.languageCode != _sourceLanguageCode)
        .toList();
  }

  /// Gets a filtered list of source languages based on current target language
  List<Language> get availableSourceLanguages {
    if (allowSameLanguage) {
      return availableLanguages;
    }
    return availableLanguages
        .where((lang) => lang.languageCode != _targetLanguageCode)
        .toList();
  }

  /// Sets the source language and notifies listeners
  Future<void> setSourceLanguage(String languageCode) async {
    if (_sourceLanguageCode == languageCode) return;

    _sourceLanguageCode = languageCode;
    await _savePreferences();

    // If source and target are now the same and that's not allowed, update target
    if (!allowSameLanguage && _sourceLanguageCode == _targetLanguageCode) {
      // Choose the next available language for the target
      for (final lang in availableLanguages) {
        if (lang.languageCode != _sourceLanguageCode) {
          _targetLanguageCode = lang.languageCode;
          break;
        }
      }
      await _savePreferences();
    }

    notifyListeners();
  }

  /// Sets the target language and notifies listeners
  Future<void> setTargetLanguage(String languageCode) async {
    if (_targetLanguageCode == languageCode) return;

    _targetLanguageCode = languageCode;
    await _savePreferences();

    // If source and target are now the same and that's not allowed, update source
    if (!allowSameLanguage && _sourceLanguageCode == _targetLanguageCode) {
      // Choose the next available language for the source
      for (final lang in availableLanguages) {
        if (lang.languageCode != _targetLanguageCode) {
          _sourceLanguageCode = lang.languageCode;
          break;
        }
      }
      await _savePreferences();
    }

    notifyListeners();
  }

  /// Swaps source and target languages
  Future<void> swapLanguages() async {
    final temp = _sourceLanguageCode;
    _sourceLanguageCode = _targetLanguageCode;
    _targetLanguageCode = temp;
    await _savePreferences();
    notifyListeners();
  }

  /// Loads saved language preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    _preferences = await SharedPreferences.getInstance();

    final savedSourceCode = _preferences?.getString(_sourceLanguageKey);
    if (savedSourceCode != null &&
        availableLanguages.any(
          (lang) => lang.languageCode == savedSourceCode,
        )) {
      _sourceLanguageCode = savedSourceCode;
    }

    final savedTargetCode = _preferences?.getString(_targetLanguageKey);
    if (savedTargetCode != null &&
        availableLanguages.any(
          (lang) => lang.languageCode == savedTargetCode,
        )) {
      _targetLanguageCode = savedTargetCode;
    }

    // Ensure we don't have same language for source and target if not allowed
    if (!allowSameLanguage &&
        _sourceLanguageCode == _targetLanguageCode &&
        availableLanguages.length > 1) {
      for (final lang in availableLanguages) {
        if (lang.languageCode != _sourceLanguageCode) {
          _targetLanguageCode = lang.languageCode;
          break;
        }
      }
    }
  }

  /// Saves current language preferences to SharedPreferences
  Future<void> _savePreferences() async {
    _preferences ??= await SharedPreferences.getInstance();

    await _preferences?.setString(_sourceLanguageKey, _sourceLanguageCode);
    await _preferences?.setString(_targetLanguageKey, _targetLanguageCode);
  }
}
