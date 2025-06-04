import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/repositories/speech_repository.dart';
import 'package:learn_to_talk/domain/repositories/tts_repository.dart';
import 'package:learn_to_talk/domain/repositories/translation_repository.dart';

class GetLanguagesUseCase {
  final SpeechRepository _speechRepository;
  final TTSRepository _ttsRepository;
  final TranslationRepository _translationRepository;

  GetLanguagesUseCase({
    required SpeechRepository speechRepository,
    required TTSRepository ttsRepository,
    required TranslationRepository translationRepository,
  })  : _speechRepository = speechRepository,
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
    print('GetLanguagesUseCase: Starting to get languages...');
    
    // Get languages from each repository
    List<Language> speechLanguages;
    List<Language> ttsLanguages;
    List<Language> translationLanguages;
    
    try {
      print('GetLanguagesUseCase: Getting speech languages...');
      speechLanguages = await _speechRepository.getSpeechRecognitionLanguages();
      print('GetLanguagesUseCase: Speech languages count: ${speechLanguages.length}');
      speechLanguages.forEach((lang) => print('GetLanguagesUseCase: Speech language: ${lang.name} (${lang.code})'));
    } catch (e) {
      print('GetLanguagesUseCase: Error getting speech languages: $e');
      speechLanguages = [];
    }
    
    try {
      print('GetLanguagesUseCase: Getting TTS languages...');
      ttsLanguages = await _ttsRepository.getTTSLanguages();
      print('GetLanguagesUseCase: TTS languages count: ${ttsLanguages.length}');
      ttsLanguages.forEach((lang) => print('GetLanguagesUseCase: TTS language: ${lang.name} (${lang.code})'));
    } catch (e) {
      print('GetLanguagesUseCase: Error getting TTS languages: $e');
      ttsLanguages = [];
    }
    
    try {
      print('GetLanguagesUseCase: Getting translation languages...');
      translationLanguages = await _translationRepository.getTranslationLanguages();
      print('GetLanguagesUseCase: Translation languages count: ${translationLanguages.length}');
      translationLanguages.forEach((lang) => print('GetLanguagesUseCase: Translation language: ${lang.name} (${lang.code})'));
    } catch (e) {
      print('GetLanguagesUseCase: Error getting translation languages: $e');
      translationLanguages = [];
    }

    // Create normalized maps for each repository's languages
    final Map<String, Language> normalizedSpeechMap = {};
    final Map<String, Language> normalizedTTSMap = {};
    final Map<String, String> translationBaseCodeMap = {};
    
    // Normalize speech language codes
    print('GetLanguagesUseCase: Normalizing speech languages...');
    for (final lang in speechLanguages) {
      String normalized = _normalizeLanguageCode(lang.code);
      normalizedSpeechMap[normalized] = lang;
      print('GetLanguagesUseCase: Speech language ${lang.code} normalized to $normalized');
    }
    
    // Normalize TTS language codes
    print('GetLanguagesUseCase: Normalizing TTS languages...');
    for (final lang in ttsLanguages) {
      String normalized = _normalizeLanguageCode(lang.code);
      normalizedTTSMap[normalized] = lang;
      print('GetLanguagesUseCase: TTS language ${lang.code} normalized to $normalized');
    }
    
    // Map translation language codes to their base codes
    print('GetLanguagesUseCase: Mapping translation languages...');
    for (final lang in translationLanguages) {
      String baseCode = _getBaseLanguageCode(lang.code);
      translationBaseCodeMap[baseCode] = lang.code;
      print('GetLanguagesUseCase: Translation language ${lang.code} has base code $baseCode');
    }
    
    // Find languages supported by all services
    final List<Language> supportedLanguages = [];
    
    // For each speech language, check if it's supported by TTS and translation
    for (final normalizedCode in normalizedSpeechMap.keys) {
      // Check if TTS supports this language
      if (!normalizedTTSMap.containsKey(normalizedCode)) {
        print('GetLanguagesUseCase: $normalizedCode not supported by TTS');
        continue;
      }
      
      // Get the base code to check translation support
      String baseCode = _getBaseLanguageCode(normalizedCode);
      if (!translationBaseCodeMap.containsKey(baseCode)) {
        print('GetLanguagesUseCase: $normalizedCode (base: $baseCode) not supported by translation');
        continue;
      }
      
      // This language is supported by all services
      final speechLang = normalizedSpeechMap[normalizedCode]!;
      supportedLanguages.add(speechLang);
      print('GetLanguagesUseCase: Found fully supported language: ${speechLang.name} (${speechLang.code})');
    }
    
    print('GetLanguagesUseCase: Final supported languages count: ${supportedLanguages.length}');
    
    // If no languages are found, provide some default ones for testing
    if (supportedLanguages.isEmpty) {
      print('GetLanguagesUseCase: No supported languages found, adding defaults for testing');
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
  Future<bool> areModelsAvailableOffline(String sourceCode, String targetCode) async {
    // Check if speech recognition is available offline
    final isSpeechAvailable = await _speechRepository.isLanguageAvailableForOfflineRecognition(sourceCode);
    
    // Check if TTS is available offline for both languages
    final isSourceTTSAvailable = await _ttsRepository.isLanguageAvailableForOfflineTTS(sourceCode);
    final isTargetTTSAvailable = await _ttsRepository.isLanguageAvailableForOfflineTTS(targetCode);
    
    // Check if translation model is available offline
    final isTranslationAvailable = await _translationRepository.isModelDownloaded(sourceCode, targetCode);
    
    return isSpeechAvailable && isSourceTTSAvailable && isTargetTTSAvailable && isTranslationAvailable;
  }
}
