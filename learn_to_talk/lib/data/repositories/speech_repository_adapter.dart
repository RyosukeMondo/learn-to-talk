import 'dart:async';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/repositories/speech_repository.dart';
import 'package:learn_to_talk/domain/repositories/speech_recognition_repository.dart';

/// Adapter class to bridge SpeechRecognitionRepository to SpeechRepository
class SpeechRepositoryAdapter implements SpeechRepository {
  final SpeechRecognitionRepository _speechRecognitionRepository;
  final StreamController<String> _recognitionResultsController = StreamController<String>.broadcast();
  final StreamController<String> _recognitionErrorsController = StreamController<String>.broadcast();

  SpeechRepositoryAdapter(this._speechRecognitionRepository) {
    // Connect the recognition results from the underlying repository to our stream
    _speechRecognitionRepository.recognitionResults.listen((RecognitionResult result) {
      _recognitionResultsController.add(result.recognizedWords);
    });
    
    // Connect error stream
    _speechRecognitionRepository.recognitionErrors.listen((error) {
      _recognitionErrorsController.add(error);
    });
  }

  @override
  Future<bool> isRecognitionAvailable() async {
    // Initialize first to check availability
    await _speechRecognitionRepository.initialize();
    return true; // If initialization succeeds, consider it available
  }

  @override
  Future<List<Language>> getSpeechRecognitionLanguages() async {
    // Convert language strings to Language objects
    final languageCodes = await _speechRecognitionRepository.getAvailableLanguages();
    return languageCodes.map((code) => Language(
      code: code,
      name: _getLanguageNameFromCode(code),
      isOfflineAvailable: false, // Default to false, can be updated later
    )).toList();
  }

  @override
  Future<bool> isLanguageAvailableForOfflineRecognition(String languageCode) async {
    // This might need implementation based on your app's capabilities
    return false; // Default implementation
  }

  @override
  Future<void> startRecognition(String languageCode) async {
    await _speechRecognitionRepository.startListening(languageCode);
  }

  @override
  Future<void> stopRecognition() async {
    await _speechRecognitionRepository.stopListening();
  }

  @override
  Stream<String> get recognitionResults => _recognitionResultsController.stream;
  
  @override
  Stream<String> get recognitionErrors => _recognitionErrorsController.stream;
  
  // Not an override, but needed for cleanup
  Future<void> dispose() async {
    await _recognitionResultsController.close();
    await _recognitionErrorsController.close();
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
