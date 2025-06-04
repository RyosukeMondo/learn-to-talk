import 'dart:async';

import 'package:learn_to_talk/data/models/language_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class SpeechDataSource {
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
        onStatus: (statusNotification) => _onSpeechStatusChanged(statusNotification),
        debugLogging: true,
      );
      
      if (_isInitialized) {
        print('SpeechDataSource: Speech recognition initialized successfully');
      } else {
        print('SpeechDataSource: Speech recognition failed to initialize');
      }
      
      return _isInitialized;
    } catch (e) {
      print('SpeechDataSource: Error initializing speech recognition: $e');
      _recognitionErrorsController.add("Failed to initialize: $e");
      return false;
    }
  }

  void _onSpeechError(SpeechRecognitionError errorNotification) {
    print('SpeechDataSource: Speech error: ${errorNotification.errorMsg}');
    _recognitionErrorsController.add(errorNotification.errorMsg);
  }

  void _onSpeechStatusChanged(String status) {
    print('SpeechDataSource: Speech status: $status');
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
      print('SpeechDataSource: Found ${locales.length} languages');
      
      if (locales.isEmpty) {
        // Fallback languages in case device doesn't provide any
        return _getFallbackLanguages();
      }
      
      return locales.map((locale) => LanguageModel(
        code: locale.localeId,
        name: locale.name,
        isOfflineAvailable: true, // These are on-device
      )).toList();
    } catch (e) {
      print('SpeechDataSource: Error getting languages: $e');
      return _getFallbackLanguages();
    }
  }
  
  List<LanguageModel> _getFallbackLanguages() {
    return [
      LanguageModel(code: 'en_US', name: 'English (US)', isOfflineAvailable: true),
      LanguageModel(code: 'ja_JP', name: 'Japanese', isOfflineAvailable: true),
      LanguageModel(code: 'fr_FR', name: 'French', isOfflineAvailable: true),
      LanguageModel(code: 'de_DE', name: 'German', isOfflineAvailable: true),
      LanguageModel(code: 'es_ES', name: 'Spanish', isOfflineAvailable: true),
      LanguageModel(code: 'zh_CN', name: 'Chinese (Simplified)', isOfflineAvailable: true),
      LanguageModel(code: 'ko_KR', name: 'Korean', isOfflineAvailable: true),
    ];
  }

  Future<bool> isLanguageAvailableForOfflineRecognition(String languageCode) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final locales = await _speech.locales();
      final bool isAvailable = locales.any((locale) => 
        locale.localeId.toLowerCase() == languageCode.toLowerCase() ||
        locale.localeId.split('_')[0].toLowerCase() == languageCode.replaceAll('-', '_').split('_')[0].toLowerCase()
      );
      print('SpeechDataSource: Language $languageCode availability: $isAvailable');
      return isAvailable;
    } catch (e) {
      print('SpeechDataSource: Error checking language availability: $e');
      return false;
    }
  }

  Future<bool> startRecognition(String languageCode) async {
    try {
      if (!_isInitialized) {
        final initSuccess = await initialize();
        if (!initSuccess) {
          print('SpeechDataSource: Failed to initialize speech recognition');
          return false;
        }
      }
      
      if (_isRecognizing) {
        await stopRecognition();
      }
      
      _languageCode = languageCode;
      print('SpeechDataSource: Starting recognition with language: $_languageCode');
      
      // First check if the language is available for offline recognition
      final isLanguageAvailable = await isLanguageAvailableForOfflineRecognition(_languageCode);
      if (!isLanguageAvailable) {
        print('SpeechDataSource: Language $_languageCode not available for offline recognition');
        // Try to continue anyway, but log the warning
      }
      
      // Call listen and handle potential null return value
      try {
        // Store the result but handle null case properly
        final result = await _speech.listen(
          onResult: _onSpeechResult,
          listenFor: const Duration(seconds: 30), // Adjust as needed
          pauseFor: const Duration(seconds: 3), // Adjust as needed
          partialResults: true,
          localeId: _languageCode,
          cancelOnError: true,
        );
        
        // Properly handle null result - assume success unless explicitly false
        if (result == null) {
          print('SpeechDataSource: Warning - _speech.listen() returned null, assuming success');
          _isRecognizing = true;
        } else {
          _isRecognizing = result;
        }
      } catch (e) {
        print('SpeechDataSource: Error during listen call: $e');
        _isRecognizing = false;
      }
      
      _listeningStatusController.add(_isRecognizing);
      return _isRecognizing;
    } catch (e) {
      print('SpeechDataSource: Failed to start listening: $e');
      _recognitionErrorsController.add("Failed to start listening: $e");
      _isRecognizing = false;
      _listeningStatusController.add(false);
      return false;
    }
  }
  
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      print('SpeechDataSource: Final result: ${result.recognizedWords}');
      _recognitionResultsController.add(result.recognizedWords);
    } else {
      print('SpeechDataSource: Partial result: ${result.recognizedWords}');
      // Optionally handle partial results if needed
    }
  }

  Future<void> stopRecognition() async {
    if (!_isRecognizing) return;
    
    print('SpeechDataSource: Stopping recognition');
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
      print('SpeechDataSource: Resources disposed');
    } catch (e) {
      print('SpeechDataSource: Error disposing speech resources: $e');
    }
  }
}
