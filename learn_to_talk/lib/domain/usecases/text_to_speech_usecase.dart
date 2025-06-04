import 'dart:async';
import 'package:learn_to_talk/domain/repositories/tts_repository.dart';

class TextToSpeechUseCase {
  final TTSRepository _ttsRepository;

  TextToSpeechUseCase({required TTSRepository ttsRepository})
      : _ttsRepository = ttsRepository;

  /// Initialize the TTS engine
  Future<void> initialize() async {
    await _ttsRepository.initTTS();
  }

  /// Speak the provided text in the given language
  Future<void> speak(String text, String languageCode) async {
    await _ttsRepository.speak(text, languageCode);
  }

  /// Stop ongoing speech
  Future<void> stop() async {
    await _ttsRepository.stop();
  }

  /// Check if the language is available for offline TTS
  Future<bool> isLanguageAvailableOffline(String languageCode) async {
    return await _ttsRepository.isLanguageAvailableForOfflineTTS(languageCode);
  }

  /// Prompt the user to download TTS data for the language
  Future<bool> promptLanguageDownload(String languageCode) async {
    return await _ttsRepository.promptLanguageInstallation(languageCode);
  }

  /// Stream that emits when speech is completed
  Stream<void> get onCompletedSpeech => _ttsRepository.onCompletedSpeech;
}
