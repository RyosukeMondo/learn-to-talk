import 'dart:async';

import 'package:learn_to_talk/data/datasources/text_to_speech_data_source.dart';

abstract class TextToSpeechRepository {
  Future<void> initialize();
  
  Future<List<String>> getAvailableLanguages();
  
  Future<List<String>> getAvailableVoices(String languageCode);
  
  Future<void> setLanguage(String languageCode);
  
  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate);
  
  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch);
  
  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume);
  
  /// Speak text with enhanced quality
  Future<void> speak(String text, {String? languageCode, String? voiceName});
  
  /// Pause speaking
  Future<void> pause();
  
  /// Stop speaking
  Future<void> stop();
  
  /// Current TTS state
  TtsState get state;
  
  /// Stream for speech completion events
  Stream<void> get onTtsCompletion;
  
  /// Stream for speech error events
  Stream<String> get onTtsError;
  
  /// Stream for speech start events
  Stream<void> get onTtsStart;
  
  /// Stream for speech progress events
  Stream<Map<String, dynamic>> get onTtsProgress;
  
  /// Clean up resources
  Future<void> dispose();
}
