import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:learn_to_talk/data/models/language_model.dart';
import 'package:logging/logging.dart';

class TranslationDataSource {
  final Map<String, OnDeviceTranslator> _translators = {};
  final modelManager = OnDeviceTranslatorModelManager();
  final Logger _logger = Logger('TranslationDataSource');

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
    _logger.info('🔍 Checking model download status: source=$sourceLanguageCode, target=$targetLanguageCode');
    
    final sourceCode = _extractLanguageCode(sourceLanguageCode);
    final targetCode = _extractLanguageCode(targetLanguageCode);
    
    _logger.info('🔍 Extracted codes: source=$sourceCode, target=$targetCode');

    // Use the same improved language matching as downloadModel
    final TranslateLanguage sourceLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == sourceCode || element.bcpCode.startsWith(sourceCode),
      orElse: () {
        _logger.warning('⚠️ Source language not found for status check: $sourceCode, fallback to English');
        return TranslateLanguage.english;
      },
    );

    final TranslateLanguage targetLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == targetCode || element.bcpCode.startsWith(targetCode),
      orElse: () {
        _logger.warning('⚠️ Target language not found for status check: $targetCode, fallback to Spanish');
        return TranslateLanguage.spanish;
      },
    );
    
    _logger.info('🎯 Checking language models: source=${sourceLanguage.bcpCode}, target=${targetLanguage.bcpCode}');

    bool isSourceDownloaded = false;
    bool isTargetDownloaded = false;
    
    try {
      isSourceDownloaded = await modelManager.isModelDownloaded(sourceLanguage.bcpCode);
      isTargetDownloaded = await modelManager.isModelDownloaded(targetLanguage.bcpCode);
      
      _logger.info('📊 Model status: source=$isSourceDownloaded (${sourceLanguage.bcpCode}), ' +
                   'target=$isTargetDownloaded (${targetLanguage.bcpCode})');
    } catch (e) {
      _logger.severe('❌ Error checking model download status: $e');
      return false; // Assume not downloaded if there's an error
    }

    return isSourceDownloaded && isTargetDownloaded;
  }

  /// Downloads the specified language models for offline use.
  ///
  /// This will download both source and target language models if they're not already
  /// available offline.
  Future<void> downloadModel(String sourceLanguageCode, String targetLanguageCode) async {
    _logger.info('🔄 Starting downloadModel: source=$sourceLanguageCode, target=$targetLanguageCode');
    
    final sourceCode = _extractLanguageCode(sourceLanguageCode);
    final targetCode = _extractLanguageCode(targetLanguageCode);
    
    _logger.info('🔄 Extracted codes: source=$sourceCode, target=$targetCode');

    // Find available languages and verify against supported models
    final List<TranslateLanguage> availableLangs = TranslateLanguage.values;
    _logger.info('Available languages in ML Kit: ${availableLangs.map((e) => e.bcpCode).toList()}');

    // Log available languages for debugging
    _logger.info('🔍 Supported languages in ML Kit: ${TranslateLanguage.values.length}');
    for (var lang in TranslateLanguage.values) {
      _logger.info('🔍 ML Kit Language: ${lang.bcpCode}');
    }

    // Try to find source language
    final TranslateLanguage sourceLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == sourceCode || element.bcpCode.startsWith(sourceCode),
      orElse: () {
        _logger.warning('⚠️ Source language not found: $sourceCode, fallback to English');
        return TranslateLanguage.english;
      },
    );

    // Try to find target language
    final TranslateLanguage targetLanguage = TranslateLanguage.values.firstWhere(
      (element) => element.bcpCode == targetCode || element.bcpCode.startsWith(targetCode),
      orElse: () {
        _logger.warning('⚠️ Target language not found: $targetCode, fallback to Spanish');
        return TranslateLanguage.spanish;
      },
    );
    
    _logger.info('🎯 Selected language models: source=${sourceLanguage.bcpCode}, target=${targetLanguage.bcpCode}');

    // Check initial download status
    bool isSourceDownloaded = false;
    bool isTargetDownloaded = false;
    
    try {
      isSourceDownloaded = await modelManager.isModelDownloaded(sourceLanguage.bcpCode);
      isTargetDownloaded = await modelManager.isModelDownloaded(targetLanguage.bcpCode);
    } catch (e) {
      _logger.severe('❌ Error checking model download status: $e');
      // Continue anyway to attempt the download
    }
    
    _logger.info('📊 Initial model status: source=$isSourceDownloaded, target=$isTargetDownloaded');

    // Source language model download
    if (!isSourceDownloaded) {
      _logger.info('⬇️ Starting source model download: ${sourceLanguage.bcpCode}');
      try {
        // Create a download listener
        bool downloadSucceeded = false;
        int downloadAttempts = 0;
        const maxAttempts = 3;
        
        while (!downloadSucceeded && downloadAttempts < maxAttempts) {
          downloadAttempts++;
          _logger.info('⬇️ Source download attempt $downloadAttempts/$maxAttempts');
          
          // Download source model and wait for completion
          await modelManager.downloadModel(sourceLanguage.bcpCode, isWifiRequired: false);
          _logger.info('✅ Source model download request sent for: ${sourceLanguage.bcpCode}');
          
          // Wait for download to complete
          for (int i = 0; i < 5; i++) {
            await Future.delayed(const Duration(seconds: 2));
            isSourceDownloaded = await modelManager.isModelDownloaded(sourceLanguage.bcpCode);
            _logger.info('📋 Source model check $i: isDownloaded=$isSourceDownloaded');
            if (isSourceDownloaded) {
              downloadSucceeded = true;
              break;
            }
          }
          
          if (downloadSucceeded) {
            _logger.info('✅ Source model successfully downloaded');
            break;
          } else {
            _logger.warning('⚠️ Source model download attempt $downloadAttempts failed, will retry');
          }
        }
        
        if (!downloadSucceeded) {
          _logger.severe('❌ Failed to download source language model after $maxAttempts attempts: ${sourceLanguage.bcpCode}');
          throw Exception('Failed to download source language model: ${sourceLanguage.bcpCode}');
        }
      } catch (e) {
        _logger.severe('❌ Error downloading source language model: $e');
        throw Exception('Error downloading source language model: $e');
      }
    }

    // Target language model download
    if (!isTargetDownloaded) {
      _logger.info('⬇️ Starting target model download: ${targetLanguage.bcpCode}');
      try {
        // Create a download listener
        bool downloadSucceeded = false;
        int downloadAttempts = 0;
        const maxAttempts = 3;
        
        while (!downloadSucceeded && downloadAttempts < maxAttempts) {
          downloadAttempts++;
          _logger.info('⬇️ Target download attempt $downloadAttempts/$maxAttempts');
          
          // Download target model and wait for completion
          await modelManager.downloadModel(targetLanguage.bcpCode, isWifiRequired: false);
          _logger.info('✅ Target model download request sent for: ${targetLanguage.bcpCode}');
          
          // Wait for download to complete
          for (int i = 0; i < 5; i++) {
            await Future.delayed(const Duration(seconds: 2));
            isTargetDownloaded = await modelManager.isModelDownloaded(targetLanguage.bcpCode);
            _logger.info('📋 Target model check $i: isDownloaded=$isTargetDownloaded');
            if (isTargetDownloaded) {
              downloadSucceeded = true;
              break;
            }
          }
          
          if (downloadSucceeded) {
            _logger.info('✅ Target model successfully downloaded');
            break;
          } else {
            _logger.warning('⚠️ Target model download attempt $downloadAttempts failed, will retry');
          }
        }
        
        if (!downloadSucceeded) {
          _logger.severe('❌ Failed to download target language model after $maxAttempts attempts: ${targetLanguage.bcpCode}');
          throw Exception('Failed to download target language model: ${targetLanguage.bcpCode}');
        }
      } catch (e) {
        _logger.severe('❌ Error downloading target language model: $e');
        throw Exception('Error downloading target language model: $e');
      }
    }
    
    // Final verification that both models are now available
    await Future.delayed(const Duration(seconds: 2)); // Wait to ensure final check is accurate
    bool finalSourceCheck = false;
    bool finalTargetCheck = false;
    
    try {
      finalSourceCheck = await modelManager.isModelDownloaded(sourceLanguage.bcpCode);
      finalTargetCheck = await modelManager.isModelDownloaded(targetLanguage.bcpCode);
    } catch (e) {
      _logger.severe('❌ Error in final verification: $e');
      throw Exception('Error checking model status: $e');
    }
    
    _logger.info('📊 Final verification: source=$finalSourceCheck, target=$finalTargetCheck');
    
    if (!finalSourceCheck || !finalTargetCheck) {
      _logger.severe('❌ Failed to verify downloaded language models');
      throw Exception('Failed to verify downloaded language models');
    }
    
    // Try to create a translator to verify models are working
    try {
      final translator = OnDeviceTranslator(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      
      _logger.info('🔄 Testing translator initialization');
      await translator.translateText('Hello world');
      await translator.close();
      _logger.info('✅ Translator test successful');
    } catch (e) {
      _logger.warning('⚠️ Translator initialization test failed: $e');
      // Don't throw, this is just a verification step
    }
    
    _logger.info('✅ Download completed successfully for both models');
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
