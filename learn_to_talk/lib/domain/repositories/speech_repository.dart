import 'dart:async';
import 'package:learn_to_talk/domain/entities/language.dart';

abstract class SpeechRepository {
  /// Checks if speech recognition is available
  Future<bool> isRecognitionAvailable();
  
  /// Returns a list of supported languages for speech recognition
  Future<List<Language>> getSpeechRecognitionLanguages();
  
  /// Checks if specific language is available for offline speech recognition
  Future<bool> isLanguageAvailableForOfflineRecognition(String languageCode);
  
  /// Starts speech recognition in the given language
  Future<void> startRecognition(String languageCode);
  
  /// Stops ongoing speech recognition
  Future<void> stopRecognition();
  
  /// Returns a stream of recognized speech results
  Stream<String> get recognitionResults;
  
  /// Returns a stream of speech recognition errors
  Stream<String> get recognitionErrors;
}
