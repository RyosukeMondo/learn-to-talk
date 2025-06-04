import 'dart:async';
import 'package:learn_to_talk/domain/entities/language.dart';

abstract class TTSRepository {
  /// Initializes the TTS engine
  Future<void> initTTS();
  
  /// Returns a list of supported languages for text-to-speech
  Future<List<Language>> getTTSLanguages();
  
  /// Checks if specific language is available for offline TTS
  Future<bool> isLanguageAvailableForOfflineTTS(String languageCode);
  
  /// Prompts the user to download TTS data for the specified language
  Future<bool> promptLanguageInstallation(String languageCode);
  
  /// Speaks the provided text in the given language
  Future<void> speak(String text, String languageCode);
  
  /// Stops ongoing speech
  Future<void> stop();
  
  /// Returns a stream that emits when speech is completed
  Stream<void> get onCompletedSpeech;
}
