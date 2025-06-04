import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:learn_to_talk/data/models/language_model.dart';

class TTSDataSource {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  
  final _completedSpeechController = StreamController<void>.broadcast();
  Stream<void> get onCompletedSpeech => _completedSpeechController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Configure TTS
    await _flutterTts.setLanguage('en-US'); // Default language
    await _flutterTts.setSpeechRate(0.5); // Slower rate for language learning
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Setup completion callback
    _flutterTts.setCompletionHandler(() {
      _completedSpeechController.add(null);
    });
    
    // Handle errors
    _flutterTts.setErrorHandler((error) {
      print('TTS Error: $error');
    });
    
    _isInitialized = true;
  }

  Future<List<LanguageModel>> getTTSLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final languages = await _flutterTts.getLanguages;
    
    // Map to language models
    return (languages as List<String>).map((code) {
      // Extract language name from code (e.g., 'en-US' -> 'English (US)')
      final name = _getLanguageNameFromCode(code);
      
      return LanguageModel(
        code: code,
        name: name,
        isOfflineAvailable: false, // Default, will check availability later
      );
    }).toList();
  }

  String _getLanguageNameFromCode(String code) {
    final Map<String, String> languageNames = {
      'en-US': 'English (US)',
      'en-GB': 'English (UK)',
      'ja-JP': 'Japanese',
      'fr-FR': 'French',
      'de-DE': 'German',
      'es-ES': 'Spanish',
      'zh-CN': 'Chinese (Simplified)',
      'zh-TW': 'Chinese (Traditional)',
      'ko-KR': 'Korean',
      'ru-RU': 'Russian',
      'it-IT': 'Italian',
    };
    
    return languageNames[code] ?? code;
  }

  Future<bool> isLanguageAvailableForOfflineTTS(String languageCode) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Using isLanguageAvailable from flutter_tts
    // Returns 1 if available, 0 if missing data, -1 if not supported
    final result = await _flutterTts.isLanguageAvailable(languageCode);
    
    // Note: This doesn't specifically check for offline availability
    // For a real app, you might need to implement a more sophisticated check
    return result == 1;
  }

  Future<bool> promptLanguageInstallation(String languageCode) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Flutter TTS doesn't provide a direct way to install language data
    // On Android, we can use TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA intent
    // This would require platform-specific code
    // For simplicity, we'll return false here
    // In a real app, you would implement platform channels to handle this
    
    return false;
  }

  Future<void> speak(String text, String languageCode) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _flutterTts.stop();
    _completedSpeechController.close();
  }
}
