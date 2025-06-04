import 'dart:async';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/repositories/tts_repository.dart';
import 'package:learn_to_talk/domain/repositories/text_to_speech_repository.dart';

/// Adapter class to bridge TextToSpeechRepository to TTSRepository
class TTSRepositoryAdapter implements TTSRepository {
  final TextToSpeechRepository _textToSpeechRepository;
  final StreamController<void> _completionController = StreamController<void>.broadcast();

  TTSRepositoryAdapter(this._textToSpeechRepository) {
    // Connect the completion events from the underlying repository to our stream
    _textToSpeechRepository.onTtsCompletion.listen((_) {
      _completionController.add(null);
    });
  }

  @override
  Future<void> initTTS() async {
    await _textToSpeechRepository.initialize();
  }

  @override
  Future<List<Language>> getTTSLanguages() async {
    try {
      print('TTSRepositoryAdapter: Getting available languages...');
      // Convert language strings to Language objects
      final languageCodes = await _textToSpeechRepository.getAvailableLanguages();
      print('TTSRepositoryAdapter: Received ${languageCodes.length} language codes');
      
      if (languageCodes.isEmpty) {
        print('TTSRepositoryAdapter: No languages received, adding fallback languages');
        // Provide fallback languages to ensure the app works
        return [
          Language(code: 'en-US', name: 'English (US)', isOfflineAvailable: true),
          Language(code: 'ja-JP', name: 'Japanese', isOfflineAvailable: true),
          Language(code: 'fr-FR', name: 'French', isOfflineAvailable: true),
          Language(code: 'de-DE', name: 'German', isOfflineAvailable: true),
          Language(code: 'es-ES', name: 'Spanish', isOfflineAvailable: true),
        ];
      }
      
      final result = languageCodes.map((code) => Language(
        code: code,
        name: _getLanguageNameFromCode(code),
        isOfflineAvailable: false, // Default to false, can be updated later
      )).toList();
      
      print('TTSRepositoryAdapter: Converted ${result.length} languages');
      result.forEach((lang) => print('TTSRepositoryAdapter: Language ${lang.name} (${lang.code})'));
      return result;
    } catch (e) {
      print('TTSRepositoryAdapter: Error getting languages: $e');
      // Return fallback languages on error
      return [
        Language(code: 'en-US', name: 'English (US)', isOfflineAvailable: true),
        Language(code: 'ja-JP', name: 'Japanese', isOfflineAvailable: true),
        Language(code: 'fr-FR', name: 'French', isOfflineAvailable: true),
      ];
    }
  }

  @override
  Future<bool> isLanguageAvailableForOfflineTTS(String languageCode) async {
    // This might need implementation based on your app's capabilities
    return false; // Default implementation
  }

  @override
  Future<bool> promptLanguageInstallation(String languageCode) async {
    // This might need implementation based on your app's capabilities
    return false; // Default implementation
  }

  /// Convert language code to format expected by TTS service
  String _formatTTSLanguageCode(String languageCode) {
    print('TTSRepositoryAdapter: Formatting TTS language code: $languageCode');
    // If code already has format like en-US, keep it
    if (languageCode.contains('-')) {
      return languageCode;
    }
    
    // If code has underscores, replace with hyphens
    if (languageCode.contains('_')) {
      return languageCode.replaceAll('_', '-');
    }
    
    // Handle special cases where we have full names
    switch (languageCode) {
      case 'English (US)': return 'en-US';
      case 'Japanese': return 'ja-JP';
      case 'French': return 'fr-FR';
      case 'German': return 'de-DE';
      case 'Spanish': return 'es-ES';
      case 'Chinese (Simplified)': return 'zh-CN';
    }
    
    // For short codes, return as is as we don't have enough info to expand
    return languageCode;
  }

  @override
  Future<void> speak(String text, String languageCode) async {
    // Format the language code for TTS service
    final formattedCode = _formatTTSLanguageCode(languageCode);
    print('TTSRepositoryAdapter: Speaking with language code: $languageCode -> $formattedCode');
    
    // First set the language, then speak
    await _textToSpeechRepository.setLanguage(formattedCode);
    await _textToSpeechRepository.speak(text);
  }

  @override
  Future<void> stop() async {
    await _textToSpeechRepository.stop();
  }

  @override
  Stream<void> get onCompletedSpeech => _completionController.stream;

  // Not an override - this method is for cleanup
  Future<void> dispose() async {
    await _completionController.close();
  }

  // Helper method to convert language codes to names
  String _getLanguageNameFromCode(String code) {
    final languageMap = {
      'en-US': 'English (US)',
      'ja-JP': 'Japanese',
      'fr-FR': 'French',
      'de-DE': 'German',
      'es-ES': 'Spanish',
      'zh-CN': 'Chinese (Simplified)',
      // Add more languages as needed
    };
    
    return languageMap[code] ?? code;
  }
}
