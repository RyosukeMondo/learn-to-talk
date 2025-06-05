import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/repositories/speech_repository.dart';
import 'package:learn_to_talk/domain/repositories/tts_repository.dart';
import 'package:learn_to_talk/domain/repositories/translation_repository.dart';
import 'package:logging/logging.dart';

class GetLanguagesUseCase {
  final SpeechRepository _speechRepository;
  final TTSRepository _ttsRepository;
  final TranslationRepository _translationRepository;
  final Logger _logger = Logger('GetLanguagesUseCase');

  GetLanguagesUseCase({
    required SpeechRepository speechRepository,
    required TTSRepository ttsRepository,
    required TranslationRepository translationRepository,
  }) : _speechRepository = speechRepository,
       _ttsRepository = ttsRepository,
       _translationRepository = translationRepository;

  /// Normalize the language code to a standard format for comparison
  /// Replaces underscores with hyphens and handles other format differences
  String _normalizeLanguageCode(String code) {
    // Replace underscores with hyphens
    String normalized = code.replaceAll('_', '-');

    // For special cases like "English (US)" convert to standard format
    if (normalized == 'English (US)') return 'en-US';
    if (normalized == 'French') return 'fr-FR';
    if (normalized == 'German') return 'de-DE';
    if (normalized == 'Spanish') return 'es-ES';
    if (normalized == 'Japanese') return 'ja-JP';
    if (normalized == 'Chinese (Simplified)') return 'zh-CN';

    return normalized;
  }

  /// Get the base language code (e.g., 'en' from 'en-US')
  String _getBaseLanguageCode(String code) {
    return code.split('-')[0].split('_')[0].toLowerCase();
  }

  /// Get languages supported by all features (speech, TTS, translation)
  /// Returns a list of languages with their availability status
  Future<List<Language>> execute() async {
    _logger.info('GetLanguagesUseCase: Starting to get languages...');

    // Get languages from each repository
    List<Language> speechLanguages;
    List<Language> ttsLanguages;
    List<Language> translationLanguages;

    try {
      _logger.info('GetLanguagesUseCase: Getting speech languages...');
      speechLanguages = await _speechRepository.getSpeechRecognitionLanguages();
      _logger.info(
        'GetLanguagesUseCase: Speech languages count: ${speechLanguages.length}',
      );
      for (final lang in speechLanguages) {
        _logger.info(
          'GetLanguagesUseCase: Speech language: ${lang.name} (${lang.code})',
        );
      }
    } catch (e) {
      _logger.info('GetLanguagesUseCase: Error getting speech languages: $e');
      speechLanguages = [];
    }

    try {
      _logger.info('GetLanguagesUseCase: Getting TTS languages...');
      ttsLanguages = await _ttsRepository.getTTSLanguages();
      _logger.info(
        'GetLanguagesUseCase: TTS languages count: ${ttsLanguages.length}',
      );
      for (final lang in ttsLanguages) {
        _logger.info(
          'GetLanguagesUseCase: TTS language: ${lang.name} (${lang.code})',
        );
      }
    } catch (e) {
      _logger.info('GetLanguagesUseCase: Error getting TTS languages: $e');
      ttsLanguages = [];
    }

    try {
      _logger.info('GetLanguagesUseCase: Getting translation languages...');
      translationLanguages =
          await _translationRepository.getTranslationLanguages();
      _logger.info(
        'GetLanguagesUseCase: Translation languages count: ${translationLanguages.length}',
      );
      for (final lang in translationLanguages) {
        _logger.info(
          'GetLanguagesUseCase: Translation language: ${lang.name} (${lang.code})',
        );
      }
    } catch (e) {
      _logger.severe('GetLanguagesUseCase: Error getting translation languages: $e');
      translationLanguages = [];
    }

    // Create normalized maps for each repository's languages
    final Map<String, Language> normalizedSpeechMap = {};
    final Map<String, Language> normalizedTTSMap = {};
    final Map<String, String> translationBaseCodeMap = {};

    // Normalize speech language codes
    _logger.info('GetLanguagesUseCase: Normalizing speech languages...');
    for (final lang in speechLanguages) {
      String normalized = _normalizeLanguageCode(lang.code);
      normalizedSpeechMap[normalized] = lang;
      _logger.info(
        'GetLanguagesUseCase: Speech language ${lang.code} normalized to $normalized',
      );
    }

    // Normalize TTS language codes
    _logger.info('GetLanguagesUseCase: Normalizing TTS languages...');
    for (final lang in ttsLanguages) {
      String normalized = _normalizeLanguageCode(lang.code);
      normalizedTTSMap[normalized] = lang;
      _logger.info(
        'GetLanguagesUseCase: TTS language ${lang.code} normalized to $normalized',
      );
    }

    // Map translation language codes to their base codes
    _logger.info('GetLanguagesUseCase: Mapping translation languages...');
    for (final lang in translationLanguages) {
      String baseCode = _getBaseLanguageCode(lang.code);
      translationBaseCodeMap[baseCode] = lang.code;
      _logger.info(
        'GetLanguagesUseCase: Translation language ${lang.code} has base code $baseCode',
      );
    }

    // Find languages supported by all services
    final List<Language> supportedLanguages = [];

    // For each speech language, check if it's supported by TTS and translation
    for (final normalizedCode in normalizedSpeechMap.keys) {
      // Check if TTS supports this language
      if (!normalizedTTSMap.containsKey(normalizedCode)) {
        _logger.info('GetLanguagesUseCase: $normalizedCode not supported by TTS');
        continue;
      }

      // Get the base code to check translation support
      String baseCode = _getBaseLanguageCode(normalizedCode);
      if (!translationBaseCodeMap.containsKey(baseCode)) {
        _logger.info(
          'GetLanguagesUseCase: $normalizedCode not supported by translation',
        );
        continue;
      }

      supportedLanguages.add(normalizedSpeechMap[normalizedCode]!);
      _logger.info(
        'GetLanguagesUseCase: Found fully supported language: ${normalizedSpeechMap[normalizedCode]!.name} (${normalizedSpeechMap[normalizedCode]!.code})',
      );
    }

    _logger.info(
      'GetLanguagesUseCase: Final supported languages count: ${supportedLanguages.length}',
    );

    // If no languages are found, provide some default ones for testing
    if (supportedLanguages.isEmpty) {
      _logger.info(
        'GetLanguagesUseCase: No supported languages found, adding defaults for testing',
      );
      supportedLanguages.addAll([
        Language(code: 'en-US', name: 'English (US)', isOfflineAvailable: true),
        Language(code: 'fr-FR', name: 'French', isOfflineAvailable: true),
        Language(code: 'de-DE', name: 'German', isOfflineAvailable: true),
        Language(code: 'es-ES', name: 'Spanish', isOfflineAvailable: true),
        Language(code: 'ja-JP', name: 'Japanese', isOfflineAvailable: true),
      ]);
    }

    return supportedLanguages;
  }

  /// Check if all necessary models are available offline for the given language pair
  Future<bool> areModelsAvailableOffline(
    String sourceCode,
    String targetCode,
  ) async {
    // Check if speech recognition is available offline
    final isSpeechAvailable = await _speechRepository
        .isLanguageAvailableForOfflineRecognition(sourceCode);

    // Check if TTS is available offline for both languages
    final isSourceTTSAvailable = await _ttsRepository
        .isLanguageAvailableForOfflineTTS(sourceCode);
    final isTargetTTSAvailable = await _ttsRepository
        .isLanguageAvailableForOfflineTTS(targetCode);

    // Check if translation model is available offline
    final isTranslationAvailable = await _translationRepository
        .isModelDownloaded(sourceCode, targetCode);

    return isSpeechAvailable &&
        isSourceTTSAvailable &&
        isTargetTTSAvailable &&
        isTranslationAvailable;
  }
}
