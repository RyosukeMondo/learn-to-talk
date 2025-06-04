import 'dart:async';
import 'package:learn_to_talk/domain/repositories/speech_repository.dart';

class SpeechRecognitionUseCase {
  final SpeechRepository _speechRepository;

  SpeechRecognitionUseCase({required SpeechRepository speechRepository})
      : _speechRepository = speechRepository;

  /// Check if speech recognition is available on the device
  Future<bool> isAvailable() {
    return _speechRepository.isRecognitionAvailable();
  }

  /// Start speech recognition in the given language
  Future<void> startListening(String languageCode) async {
    await _speechRepository.startRecognition(languageCode);
  }

  /// Stop ongoing speech recognition
  Future<void> stopListening() async {
    await _speechRepository.stopRecognition();
  }

  /// Stream of recognized speech results
  Stream<String> get recognitionResults => _speechRepository.recognitionResults;

  /// Stream of speech recognition errors
  Stream<String> get recognitionErrors => _speechRepository.recognitionErrors;
  
  /// Validate if the recognized text matches the expected text
  /// Returns a double between 0.0 and 1.0 representing the similarity
  double validateSpeech(String recognized, String expected) {
    if (recognized.isEmpty || expected.isEmpty) return 0.0;
    
    // Normalize strings for comparison (lowercase, trim whitespace)
    final normalizedRecognized = recognized.toLowerCase().trim();
    final normalizedExpected = expected.toLowerCase().trim();
    
    if (normalizedRecognized == normalizedExpected) return 1.0;
    
    // Calculate word-based similarity score
    final recognizedWords = normalizedRecognized.split(' ');
    final expectedWords = normalizedExpected.split(' ');
    
    int matchingWords = 0;
    for (final word in recognizedWords) {
      if (expectedWords.contains(word)) {
        matchingWords++;
      }
    }
    
    // Calculate similarity score based on matching words
    final totalWords = (recognizedWords.length + expectedWords.length) / 2;
    final similarity = matchingWords / totalWords;
    
    return similarity;
  }
  
  /// Get detailed feedback on differences between recognized and expected text
  Map<String, dynamic> getDetailedFeedback(String recognized, String expected) {
    // Normalize strings for comparison
    final normalizedRecognized = recognized.toLowerCase().trim();
    final normalizedExpected = expected.toLowerCase().trim();
    
    final recognizedWords = normalizedRecognized.split(' ');
    final expectedWords = normalizedExpected.split(' ');
    
    final missingWords = expectedWords.where((word) => !recognizedWords.contains(word)).toList();
    final extraWords = recognizedWords.where((word) => !expectedWords.contains(word)).toList();
    
    return {
      'missingWords': missingWords,
      'extraWords': extraWords,
      'correctWords': expectedWords.where((word) => recognizedWords.contains(word)).toList(),
    };
  }
}
