import 'dart:async';

// Custom recognition result model
class RecognitionResult {
  final String recognizedWords;
  final bool finalResult;
  final double confidence;
  
  RecognitionResult({
    required this.recognizedWords,
    required this.finalResult,
    this.confidence = 0.0,
  });
}

abstract class SpeechRecognitionRepository {
  Future<void> initialize();
  
  Future<List<String>> getAvailableLanguages();
  
  Future<bool> startListening(String languageCode);
  
  Future<void> stopListening();
  
  bool isListening();
  
  Stream<RecognitionResult> get recognitionResults;
  
  Stream<String> get recognitionErrors;
  
  Stream<bool> get listeningStatus;
  
  Future<void> dispose();
}
