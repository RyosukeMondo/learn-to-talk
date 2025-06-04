import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:learn_to_talk/data/models/language_model.dart';

class TranslationDataSource {
  final Map<String, OnDeviceTranslator> _translators = {};
  final modelManager = OnDeviceTranslatorModelManager();

  Future<void> initialize() async {
    // Nothing to initialize at this point
  }

  /// Translates the text from the source language to the target language.
  ///
  /// This method creates or reuses an on-device translator with the given language pair.
  /// It returns the translated text.
  Future<String> translate(String text, String sourceLanguageCode, String targetLanguageCode) async {
    final translator = await _getTranslator(sourceLanguageCode, targetLanguageCode);
    final translatedText = await translator.translateText(text);
    return translatedText;
  }

  /// Checks if the specified language model is downloaded and available for offline use.
  ///
  /// Returns true if both source and target language models are downloaded, false otherwise.
  Future<bool> isModelDownloaded(String sourceLanguageCode, String targetLanguageCode) async {
    final sourceCode = _extractLanguageCode(sourceLanguageCode);
    final targetCode = _extractLanguageCode(targetLanguageCode);

    final TranslateLanguage sourceLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == sourceCode,
      orElse: () => TranslateLanguage.english,
    );

    final TranslateLanguage targetLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == targetCode,
      orElse: () => TranslateLanguage.spanish,
    );

    final isSourceDownloaded = await modelManager.isModelDownloaded(sourceLanguage.bcpCode);
    final isTargetDownloaded = await modelManager.isModelDownloaded(targetLanguage.bcpCode);

    return isSourceDownloaded && isTargetDownloaded;
  }

  /// Downloads the specified language models for offline use.
  ///
  /// This will download both source and target language models if they're not already
  /// available offline.
  Future<void> downloadModel(String sourceLanguageCode, String targetLanguageCode) async {
    final sourceCode = _extractLanguageCode(sourceLanguageCode);
    final targetCode = _extractLanguageCode(targetLanguageCode);

    final TranslateLanguage sourceLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == sourceCode,
      orElse: () => TranslateLanguage.english,
    );

    final TranslateLanguage targetLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == targetCode,
      orElse: () => TranslateLanguage.spanish,
    );

    // Only download if not already downloaded
    final isSourceDownloaded = await modelManager.isModelDownloaded(sourceLanguage.bcpCode);
    final isTargetDownloaded = await modelManager.isModelDownloaded(targetLanguage.bcpCode);

    if (!isSourceDownloaded) {
      await modelManager.downloadModel(sourceLanguage.bcpCode, isWifiRequired: false);
    }

    if (!isTargetDownloaded) {
      await modelManager.downloadModel(targetLanguage.bcpCode, isWifiRequired: false);
    }
  }

  /// Deletes the specified language models to free up device storage.
  ///
  /// This will remove both source and target language models if they are currently
  /// downloaded.
  Future<void> deleteModel(String sourceLanguageCode, String targetLanguageCode) async {
    final sourceCode = _extractLanguageCode(sourceLanguageCode);
    final targetCode = _extractLanguageCode(targetLanguageCode);

    final TranslateLanguage sourceLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == sourceCode,
      orElse: () => TranslateLanguage.english,
    );

    final TranslateLanguage targetLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == targetCode,
      orElse: () => TranslateLanguage.spanish,
    );

    // Only delete if already downloaded
    final isSourceDownloaded = await modelManager.isModelDownloaded(sourceLanguage.bcpCode);
    final isTargetDownloaded = await modelManager.isModelDownloaded(targetLanguage.bcpCode);

    if (isSourceDownloaded) {
      await modelManager.deleteModel(sourceLanguage.bcpCode);
    }

    if (isTargetDownloaded) {
      await modelManager.deleteModel(targetLanguage.bcpCode);
    }
  }

  /// Gets a list of all supported languages for translation.
  ///
  /// Returns a list of Language objects that can be used for translation.
  Future<List<LanguageModel>> getSupportedLanguages() async {
    final List<LanguageModel> supportedLanguages = [];
    
    // Add all TranslateLanguage values as supported languages
    for (final translateLanguage in TranslateLanguage.values) {
      supportedLanguages.add(
        LanguageModel(
          code: translateLanguage.bcpCode,
          name: _getLanguageNameFromCode(translateLanguage.bcpCode),
          isOfflineAvailable: true,
        ),
      );
    }

    return supportedLanguages;
  }

  /// Helper method to extract the base language code from a BCP-47 code
  ///
  /// For example, converts 'en-US' to 'en'
  String _extractLanguageCode(String languageCode) {
    return languageCode.split('-')[0].toLowerCase();
  }

  /// Gets a human-readable language name from a language code
  String _getLanguageNameFromCode(String languageCode) {
    final Map<String, String> languageNames = {
      'af': 'Afrikaans',
      'ar': 'Arabic',
      'be': 'Belarusian',
      'bg': 'Bulgarian',
      'bn': 'Bengali',
      'ca': 'Catalan',
      'cs': 'Czech',
      'cy': 'Welsh',
      'da': 'Danish',
      'de': 'German',
      'el': 'Greek',
      'en': 'English',
      'eo': 'Esperanto',
      'es': 'Spanish',
      'et': 'Estonian',
      'fa': 'Persian',
      'fi': 'Finnish',
      'fr': 'French',
      'ga': 'Irish',
      'gl': 'Galician',
      'gu': 'Gujarati',
      'he': 'Hebrew',
      'hi': 'Hindi',
      'hr': 'Croatian',
      'ht': 'Haitian',
      'hu': 'Hungarian',
      'id': 'Indonesian',
      'is': 'Icelandic',
      'it': 'Italian',
      'ja': 'Japanese',
      'ka': 'Georgian',
      'kn': 'Kannada',
      'ko': 'Korean',
      'lt': 'Lithuanian',
      'lv': 'Latvian',
      'mk': 'Macedonian',
      'mr': 'Marathi',
      'ms': 'Malay',
      'mt': 'Maltese',
      'nl': 'Dutch',
      'no': 'Norwegian',
      'pl': 'Polish',
      'pt': 'Portuguese',
      'ro': 'Romanian',
      'ru': 'Russian',
      'sk': 'Slovak',
      'sl': 'Slovenian',
      'sq': 'Albanian',
      'sv': 'Swedish',
      'sw': 'Swahili',
      'ta': 'Tamil',
      'te': 'Telugu',
      'th': 'Thai',
      'tl': 'Tagalog',
      'tr': 'Turkish',
      'uk': 'Ukrainian',
      'ur': 'Urdu',
      'vi': 'Vietnamese',
      'zh': 'Chinese',
    };

    return languageNames[languageCode] ?? languageCode;
  }

  /// Creates or retrieves an existing translator for the given language pair
  Future<OnDeviceTranslator> _getTranslator(String sourceLanguageCode, String targetLanguageCode) async {
    final sourceCode = _extractLanguageCode(sourceLanguageCode);
    final targetCode = _extractLanguageCode(targetLanguageCode);
    
    final TranslateLanguage sourceLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == sourceCode,
      orElse: () => TranslateLanguage.english,
    );

    final TranslateLanguage targetLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == targetCode,
      orElse: () => TranslateLanguage.spanish,
    );

    final key = '${sourceLanguage.bcpCode}-${targetLanguage.bcpCode}';
    
    if (_translators.containsKey(key)) {
      return _translators[key]!;
    }
    
    // Create a new translator using the correct constructor
    final translator = OnDeviceTranslator(
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    _translators[key] = translator;
    return translator;
  }

  /// Cleans up resources by closing all translator instances
  Future<void> dispose() async {
    // Close all translators
    for (final translator in _translators.values) {
      await translator.close();
    }
    _translators.clear();
  }
}
