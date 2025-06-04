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

  /// Get languages supported by all features (speech, TTS, translation)
  /// Returns a list of languages with their availability status
  Future<List<Language>> execute() async {
    // Get languages from each repository
    final speechLanguages = await _speechRepository.getSpeechRecognitionLanguages();
    final ttsLanguages = await _ttsRepository.getTTSLanguages();
    final translationLanguages = await _translationRepository.getTranslationLanguages();

    // Find common languages (those supported by all three services)
    final Map<String, Language> languageMap = {};

    // Process speech languages
    for (final language in speechLanguages) {
      languageMap[language.code] = language;
    }

    // Filter for TTS support
    final ttsLanguageCodes = ttsLanguages.map((l) => l.code).toSet();
    languageMap.removeWhere((code, _) => !ttsLanguageCodes.contains(code));

    // Filter for translation support
    // Note: Translation uses shorter language codes (e.g., 'en' instead of 'en-US')
    // So we'll check if the beginning of the code matches
    final translationLanguageCodes = translationLanguages.map((l) => l.code).toSet();
    languageMap.removeWhere((code, _) {
      final shortCode = code.split('-')[0];
      return !translationLanguageCodes.any((tCode) => tCode == shortCode);
    });

    return languageMap.values.toList();
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
