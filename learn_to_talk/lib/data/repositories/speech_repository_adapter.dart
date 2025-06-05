import 'dart:async';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/repositories/speech_repository.dart';
import 'package:learn_to_talk/domain/repositories/speech_recognition_repository.dart';
import 'package:logging/logging.dart';

/// Adapter class to bridge SpeechRecognitionRepository to SpeechRepository
class SpeechRepositoryAdapter implements SpeechRepository {
  final SpeechRecognitionRepository _speechRecognitionRepository;
  final StreamController<String> _recognitionResultsController =
      StreamController<String>.broadcast();
  final StreamController<String> _recognitionErrorsController =
      StreamController<String>.broadcast();
  final Logger _logger = Logger('SpeechRepositoryAdapter');

  SpeechRepositoryAdapter(this._speechRecognitionRepository) {
    // Connect the recognition results from the underlying repository to our stream
    _speechRecognitionRepository.recognitionResults.listen((
      RecognitionResult result,
    ) {
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
    try {
      _logger.info('SpeechRepositoryAdapter: Getting available languages...');
      // Convert language strings to Language objects
      final languageCodes =
          await _speechRecognitionRepository.getAvailableLanguages();
      _logger.info(
        'SpeechRepositoryAdapter: Received ${languageCodes.length} language codes',
      );

      if (languageCodes.isEmpty) {
        _logger.info(
          'SpeechRepositoryAdapter: No languages received, adding fallback languages',
        );
        // Provide fallback languages to ensure the app works
        return [
          Language(
            code: 'en-US',
            name: 'English (US)',
            isOfflineAvailable: true,
          ),
          Language(code: 'ja-JP', name: 'Japanese', isOfflineAvailable: true),
          Language(code: 'fr-FR', name: 'French', isOfflineAvailable: true),
          Language(code: 'de-DE', name: 'German', isOfflineAvailable: true),
          Language(code: 'es-ES', name: 'Spanish', isOfflineAvailable: true),
        ];
      }

      final result =
          languageCodes
              .map(
                (code) => Language(
                  code: code,
                  name: _getLanguageNameFromCode(code),
                  isOfflineAvailable:
                      false, // Default to false, can be updated later
                ),
              )
              .toList();

      _logger.info(
        'SpeechRepositoryAdapter: Converted ${result.length} languages',
      );
      for (final lang in result) {
        _logger.info(
          'SpeechRepositoryAdapter: Language ${lang.name} (${lang.code})',
        );
      }
      return result;
    } catch (e) {
      _logger.info('SpeechRepositoryAdapter: Error getting languages: $e');
      // Return fallback languages on error
      return [
        Language(code: 'en-US', name: 'English (US)', isOfflineAvailable: true),
        Language(code: 'ja-JP', name: 'Japanese', isOfflineAvailable: true),
        Language(code: 'fr-FR', name: 'French', isOfflineAvailable: true),
      ];
    }
  }

  @override
  Future<bool> isLanguageAvailableForOfflineRecognition(
    String languageCode,
  ) async {
    // This might need implementation based on your app's capabilities
    return false; // Default implementation
  }

  /// Convert language code to format expected by speech recognition service
  String _formatSpeechLanguageCode(String languageCode) {
    _logger.info(
      'SpeechRepositoryAdapter: Formatting speech language code: $languageCode',
    );
    // If code already has format like en_US with underscore (which speech recognition expects), keep it
    if (languageCode.contains('_')) {
      return languageCode;
    }

    // If code has hyphens, replace with underscores
    if (languageCode.contains('-')) {
      return languageCode.replaceAll('-', '_');
    }

    // Handle special cases where we have full names
    switch (languageCode) {
      case 'English (US)':
        return 'en_US';
      case 'Japanese':
        return 'ja_JP';
      case 'French':
        return 'fr_FR';
      case 'German':
        return 'de_DE';
      case 'Spanish':
        return 'es_ES';
      case 'Chinese (Simplified)':
        return 'zh_CN';
      case 'Korean':
        return 'ko_KR';
    }

    // For short codes, use default locale if available
    switch (languageCode) {
      case 'en':
        return 'en_US';
      case 'ja':
        return 'ja_JP';
      case 'fr':
        return 'fr_FR';
      case 'de':
        return 'de_DE';
      case 'es':
        return 'es_ES';
      case 'zh':
        return 'zh_CN';
      case 'ko':
        return 'ko_KR';
    }

    return languageCode;
  }

  @override
  Future<void> startRecognition(String languageCode) async {
    // Format the language code for speech recognition service
    final formattedCode = _formatSpeechLanguageCode(languageCode);
    _logger.info(
      'SpeechRepositoryAdapter: Starting recognition with language code: $languageCode -> $formattedCode',
    );

    try {
      final success = await _speechRecognitionRepository.startListening(
        formattedCode,
      );
      _logger.info(
        'SpeechRepositoryAdapter: Speech recognition started: $success',
      );

      // If recognition wasn't successful, emit an error
      if (success == false) {
        _recognitionErrorsController.add(
          'Failed to start speech recognition for $formattedCode',
        );
      }
    } catch (e) {
      _logger.warning(
        'SpeechRepositoryAdapter: Error starting recognition: $e',
      );
      _recognitionErrorsController.add('Error starting speech recognition: $e');
    }
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
      'ko-KR': 'Korean',
      // Add more languages as needed
    };

    return languageMap[code] ?? code;
  }
}
