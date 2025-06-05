import 'dart:async';

import 'package:logging/logging.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart' as stt_result;
import 'package:permission_handler/permission_handler.dart';

/// Represents a speech recognition result
class RecognitionResult {
  final String recognizedWords;
  final bool finalResult;
  final double confidence;

  RecognitionResult({
    required this.recognizedWords,
    required this.finalResult,
    this.confidence = 0.0,
  });

  /// Factory to create from speech_to_text result
  factory RecognitionResult.fromSpeechResult(
    stt_result.SpeechRecognitionResult result,
  ) {
    return RecognitionResult(
      recognizedWords: result.recognizedWords,
      finalResult: result.finalResult,
      confidence: result.confidence,
    );
  }
}

class SpeechRecognitionDataSource {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  final Logger _logger = Logger('SpeechRecognitionDataSource');

  // Stream controllers for handling speech events
  final _recognitionResultsController =
      StreamController<RecognitionResult>.broadcast();
  final _recognitionErrorController = StreamController<String>.broadcast();
  final _listeningStatusController = StreamController<bool>.broadcast();

  // Expose streams for listeners
  Stream<RecognitionResult> get recognitionResults =>
      _recognitionResultsController.stream;
  Stream<String> get recognitionErrors => _recognitionErrorController.stream;
  Stream<bool> get listeningStatus => _listeningStatusController.stream;

  Future<void> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }

      // Initialize speech to text
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          final isListening = status == 'listening';
          _isListening = isListening;
          _listeningStatusController.add(isListening);
        },
        onError: (errorNotification) {
          _recognitionErrorController.add(errorNotification.errorMsg);
          _logger.warning('Speech error: ${errorNotification.errorMsg}');
        },
      );

      _logger.info(
        'Speech recognition initialized successfully: $_speechEnabled',
      );
    } catch (e) {
      _speechEnabled = false;
      _logger.warning('Failed to initialize speech recognition: $e');
      _recognitionErrorController.add(
        'Failed to initialize speech recognition: $e',
      );
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    if (!_speechEnabled) {
      await initialize();
    }

    // Get available locales from speech_to_text
    final locales = await _speech.locales();

    // Convert to language codes
    return locales.map((locale) => locale.localeId).toList();
  }

  Future<bool> startListening(String languageCode) async {
    if (!_speechEnabled) {
      _logger.info('Speech not enabled, initializing first');
      await initialize();
      if (!_speechEnabled) {
        _logger.warning('Speech recognition initialization failed');
        _recognitionErrorController.add("Speech recognition not initialized");
        return false;
      }
    }

    if (_isListening) {
      _logger.info('Already listening, stopping first');
      await stopListening();
    }

    try {
      _logger.info('Starting listening in language: $languageCode');

      // Check if language is available
      final locales = await _speech.locales();
      final bool isLanguageSupported = locales.any(
        (locale) =>
            locale.localeId.toLowerCase() == languageCode.toLowerCase() ||
            locale.localeId.split('_')[0].toLowerCase() ==
                languageCode.replaceAll('-', '_').split('_')[0].toLowerCase(),
      );

      if (!isLanguageSupported) {
        _logger.warning(
          'Warning: Language $languageCode might not be supported by the device',
        );
        // Continue anyway as some devices don't properly report all supported languages
      } else {
        _logger.info('Language $languageCode is supported by the device');
      }

      // Start listening with language - with null safety handling
      final result = await _speech.listen(
        onResult: (result) {
          // Convert speech_to_text result to our RecognitionResult format
          final recognitionResult = RecognitionResult.fromSpeechResult(result);
          _recognitionResultsController.add(recognitionResult);
        },
        localeId: languageCode,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        ),
      );

      // Handle null return value (happens with some languages like Korean)
      if (result == null) {
        _logger.info(
          'Speech.listen() returned null, assuming success for language: $languageCode',
        );
        // For languages like Korean where listen() returns null, we'll assume listening started successfully
        // but monitor status via the status handler
        _isListening = true;
      } else {
        _isListening = result;
        _logger.info('Started listening with result: $_isListening');
      }

      _listeningStatusController.add(_isListening);
      return _isListening;
    } catch (e) {
      _logger.warning("Failed to start listening: $e");
      _recognitionErrorController.add("Failed to start listening: $e");
      _isListening = false;
      _listeningStatusController.add(false);
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      _listeningStatusController.add(false);
    } catch (e) {
      _logger.warning('Error stopping listening: $e');
      _recognitionErrorController.add("Error stopping listening: $e");
    }
  }

  bool isListening() {
    return _isListening;
  }

  Future<void> dispose() async {
    await stopListening();

    if (!_recognitionResultsController.isClosed) {
      await _recognitionResultsController.close();
    }

    if (!_recognitionErrorController.isClosed) {
      await _recognitionErrorController.close();
    }

    if (!_listeningStatusController.isClosed) {
      await _listeningStatusController.close();
    }
  }
}
