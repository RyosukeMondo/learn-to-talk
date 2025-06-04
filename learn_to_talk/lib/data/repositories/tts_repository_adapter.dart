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
    // Convert language strings to Language objects
    final languageCodes = await _textToSpeechRepository.getAvailableLanguages();
    return languageCodes.map((code) => Language(
      code: code,
      name: _getLanguageNameFromCode(code),
      isOfflineAvailable: false, // Default to false, can be updated later
    )).toList();
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

  @override
  Future<void> speak(String text, String languageCode) async {
    // First set the language, then speak
    await _textToSpeechRepository.setLanguage(languageCode);
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
