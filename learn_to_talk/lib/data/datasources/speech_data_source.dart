import 'dart:async';

import 'package:learn_to_talk/data/models/language_model.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class SpeechDataSource {
  // Logger for this class
  final Logger _logger = Logger('SpeechDataSource');
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isRecognizing = false;
  String _languageCode = 'en-US';

  final _recognitionResultsController = StreamController<String>.broadcast();
  final _recognitionErrorsController = StreamController<String>.broadcast();
  final _listeningStatusController = StreamController<bool>.broadcast();

  Stream<String> get recognitionResults => _recognitionResultsController.stream;
  Stream<String> get recognitionErrors => _recognitionErrorsController.stream;
  Stream<bool> get listeningStatus => _listeningStatusController.stream;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }

      // Initialize on-device speech recognition
      _isInitialized = await _speech.initialize(
        onError: (errorNotification) => _onSpeechError(errorNotification),
        onStatus:
            (statusNotification) => _onSpeechStatusChanged(statusNotification),
        debugLogging: true,
      );

      if (_isInitialized) {
        _logger.info('Speech recognition initialized successfully');
      } else {
        _logger.warning('Speech recognition failed to initialize');
      }

      return _isInitialized;
    } catch (e) {
      _logger.severe('Error initializing speech recognition', e);
      _recognitionErrorsController.add("Failed to initialize: $e");
      return false;
    }
  }

  void _onSpeechError(SpeechRecognitionError errorNotification) {
    _logger.warning('Speech error: ${errorNotification.errorMsg}');
    _recognitionErrorsController.add(errorNotification.errorMsg);
  }

  void _onSpeechStatusChanged(String status) {
    _logger.info('Speech status: $status');
    _isRecognizing = status == 'listening';
    _listeningStatusController.add(_isRecognizing);
  }

  Future<bool> isRecognitionAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.isAvailable;
  }

  Future<List<LanguageModel>> getSpeechRecognitionLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Get on-device speech recognition languages
      final locales = await _speech.locales();
      _logger.info('Found ${locales.length} languages');

      if (locales.isEmpty) {
        // Fallback languages in case device doesn't provide any
        return _getFallbackLanguages();
      }

      return locales
          .map(
            (locale) => LanguageModel(
              code: locale.localeId,
              name: locale.name,
              isOfflineAvailable: true, // These are on-device
            ),
          )
          .toList();
    } catch (e) {
      _logger.warning('Error getting languages', e);
      return _getFallbackLanguages();
    }
  }

  List<LanguageModel> _getFallbackLanguages() {
    return [
      LanguageModel(
        code: 'en_US',
        name: 'English (US)',
        isOfflineAvailable: true,
      ),
      LanguageModel(code: 'ja_JP', name: 'Japanese', isOfflineAvailable: true),
      LanguageModel(code: 'fr_FR', name: 'French', isOfflineAvailable: true),
      LanguageModel(code: 'de_DE', name: 'German', isOfflineAvailable: true),
      LanguageModel(code: 'es_ES', name: 'Spanish', isOfflineAvailable: true),
      LanguageModel(
        code: 'zh_CN',
        name: 'Chinese (Simplified)',
        isOfflineAvailable: true,
      ),
      LanguageModel(code: 'ko_KR', name: 'Korean', isOfflineAvailable: true),
    ];
  }

  Future<bool> isLanguageAvailableForOfflineRecognition(
    String languageCode,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final locales = await _speech.locales();
      final bool isAvailable = locales.any(
        (locale) =>
            locale.localeId.toLowerCase() == languageCode.toLowerCase() ||
            locale.localeId.split('_')[0].toLowerCase() ==
                languageCode.replaceAll('-', '_').split('_')[0].toLowerCase(),
      );
      _logger.info('Language $languageCode availability: $isAvailable');
      return isAvailable;
    } catch (e) {
      _logger.warning('Error checking language availability', e);
      return false;
    }
  }

  Future<bool> startRecognition(String languageCode) async {
    try {
      if (!_isInitialized) {
        final initSuccess = await initialize();
        if (!initSuccess) {
          _logger.warning('Failed to initialize speech recognition');
          return false;
        }
      }

      if (_isRecognizing) {
        await stopRecognition();
      }

      _languageCode = languageCode;
      _logger.info('Starting recognition with language: $_languageCode');

      // First check if the language is available for offline recognition
      final isLanguageAvailable =
          await isLanguageAvailableForOfflineRecognition(_languageCode);
      if (!isLanguageAvailable) {
        _logger.warning(
          'Language $_languageCode not available for offline recognition',
        );
        // Try to continue anyway, but log the warning
      }

      // Call listen and handle potential null return value
      try {
        // Store the result but handle null case properly
        final result = await _speech.listen(
          onResult: _onSpeechResult,
          listenFor: const Duration(seconds: 30), // Adjust as needed
          pauseFor: const Duration(seconds: 3), // Adjust as needed
          localeId: _languageCode,
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: true,
          ),
        );

        // Properly handle null result - assume success unless explicitly false
        if (result == null) {
          _logger.warning('_speech.listen() returned null, assuming success');
          _isRecognizing = true;
        } else {
          _isRecognizing = result;
        }
      } catch (e) {
        _logger.severe('Error during listen call', e);
        _isRecognizing = false;
      }

      _listeningStatusController.add(_isRecognizing);
      return _isRecognizing;
    } catch (e) {
      _logger.severe('Failed to start listening', e);
      _recognitionErrorsController.add("Failed to start listening: $e");
      _isRecognizing = false;
      _listeningStatusController.add(false);
      return false;
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      _logger.info('Final result: ${result.recognizedWords}');
      _recognitionResultsController.add(result.recognizedWords);
    } else {
      _logger.fine('Partial result: ${result.recognizedWords}');
      // Optionally handle partial results if needed
    }
  }

  Future<void> stopRecognition() async {
    if (!_isRecognizing) return;

    _logger.info('Stopping recognition');
    await _speech.stop();
    _isRecognizing = false;
    _listeningStatusController.add(false);
  }

  Future<void> dispose() async {
    try {
      await stopRecognition();
      await _recognitionResultsController.close();
      await _recognitionErrorsController.close();
      await _listeningStatusController.close();
      _logger.info('Resources disposed');
    } catch (e) {
      _logger.severe('Error disposing speech resources', e);
    }
  }
}
