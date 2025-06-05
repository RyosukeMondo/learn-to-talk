import 'dart:async';
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:logging/logging.dart';

enum TtsState { playing, stopped, paused, continued }

class TextToSpeechDataSource {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  TtsState _ttsState = TtsState.stopped;
  final Logger _logger = Logger('TextToSpeechDataSource');
  // Default voice quality settings
  double _volume = 1.0;
  double _pitch = 1.0;
  double _rate = 0.5; // Slowed down for language learning

  // Stream controllers for handling TTS events
  final _ttsCompletionController = StreamController<void>.broadcast();
  final _ttsErrorController = StreamController<String>.broadcast();
  final _ttsStartController = StreamController<void>.broadcast();
  final _ttsProgressController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Expose streams for listeners
  Stream<void> get onTtsCompletion => _ttsCompletionController.stream;
  Stream<String> get onTtsError => _ttsErrorController.stream;
  Stream<void> get onTtsStart => _ttsStartController.stream;
  Stream<Map<String, dynamic>> get onTtsProgress =>
      _ttsProgressController.stream;

  Future<void> initialize() async {
    if (!_initialized) {
      // Enable shared instance for better audio quality
      await _flutterTts.setSharedInstance(true);

      // Set initial quality parameters
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setSpeechRate(_rate);

      // Enhanced audio quality on iOS
      if (Platform.isIOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }

      // Set up event handlers
      _flutterTts.setCompletionHandler(() {
        _ttsState = TtsState.stopped;
        _ttsCompletionController.add(null);
      });

      _flutterTts.setErrorHandler((error) {
        _ttsState = TtsState.stopped;
        _ttsErrorController.add(error.toString());
      });

      _flutterTts.setStartHandler(() {
        _ttsState = TtsState.playing;
        _ttsStartController.add(null);
      });

      _flutterTts.setProgressHandler((
        String text,
        int start,
        int end,
        String word,
      ) {
        _ttsProgressController.add({
          'text': text,
          'start': start,
          'end': end,
          'word': word,
        });
      });

      _initialized = true;
      _logger.info(
        'Text-to-speech initialized successfully with enhanced quality settings',
      );
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    if (!_initialized) {
      await initialize();
    }

    final languages = await _flutterTts.getLanguages;
    return languages.cast<String>();
  }

  Future<List<dynamic>> getAvailableVoices(String languageCode) async {
    if (!_initialized) {
      await initialize();
    }

    final voices = await _flutterTts.getVoices;
    final voiceList = voices as List<dynamic>;

    // Filter voices for the specified language
    final filteredVoices =
        voiceList
            .where((voice) => voice['locale'].toString().contains(languageCode))
            .toList();

    return filteredVoices;
  }

  Future<void> setLanguage(String languageCode) async {
    if (!_initialized) {
      await initialize();
    }

    await _flutterTts.setLanguage(languageCode);

    // Try to find the best quality voice for this language
    await _setBestVoiceForLanguage(languageCode);
  }

  Future<void> _setBestVoiceForLanguage(String languageCode) async {
    final voices = await getAvailableVoices(languageCode);

    if (voices.isEmpty) return;

    // Try to find a high-quality voice
    // On iOS/macOS, voices with "premium", "enhanced", or "neural" tend to be better quality
    // On Android, voices with "network" or higher quality value tend to be better

    // Find preferred voices
    var preferredVoice = voices.firstWhere(
      (voice) => _isHighQualityVoice(voice),
      orElse: () => voices.first,
    );

    // Set voice if found
    if (preferredVoice != null) {
      if (Platform.isIOS || Platform.isMacOS) {
        await _flutterTts.setVoice({
          "name": preferredVoice["name"],
          "locale": preferredVoice["locale"],
        });
      } else if (Platform.isAndroid) {
        await _flutterTts.setVoice({
          "name": preferredVoice["name"],
          "locale": preferredVoice["locale"],
        });
      }

      _logger.info(
        'Set high-quality voice: ${preferredVoice["name"]} for $languageCode',
      );
    }
  }

  bool _isHighQualityVoice(dynamic voice) {
    final name = voice["name"].toString().toLowerCase();

    if (Platform.isIOS || Platform.isMacOS) {
      return name.contains('premium') ||
          name.contains('enhanced') ||
          name.contains('neural') ||
          name.contains('siri');
    } else if (Platform.isAndroid) {
      // On Android, network voices typically have higher quality
      return voice.containsKey("networkConnectionRequired") &&
          voice["networkConnectionRequired"] == true;
    }

    return false;
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    if (rate < 0.0 || rate > 1.0) {
      throw ArgumentError('Speech rate must be between 0.0 and 1.0');
    }

    _rate = rate;
    await _flutterTts.setSpeechRate(rate);
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    if (pitch < 0.5 || pitch > 2.0) {
      throw ArgumentError('Pitch must be between 0.5 and 2.0');
    }

    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      throw ArgumentError('Volume must be between 0.0 and 1.0');
    }

    _volume = volume;
    await _flutterTts.setVolume(volume);
  }

  /// Speak text with enhanced quality
  Future<void> speak(
    String text, {
    String? languageCode,
    String? voiceName,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    // Set language if provided
    if (languageCode != null) {
      await setLanguage(languageCode);
    }

    // Set specific voice if provided
    if (voiceName != null) {
      await _flutterTts.setVoice({"name": voiceName});
    }

    // Break long text into sentences for more natural speaking
    if (text.length > 100) {
      await _speakLongText(text);
    } else {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _speakLongText(String text) async {
    // Simple sentence splitting
    final sentences =
        text
            .split(RegExp(r'(?<=[.!?])\s+'))
            .where((s) => s.trim().isNotEmpty)
            .toList();

    for (final sentence in sentences) {
      if (_ttsState == TtsState.stopped) {
        await _flutterTts.speak(sentence);
        // Wait for completion before speaking next sentence
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        break; // Stop if interrupted
      }
    }
  }

  Future<void> pause() async {
    if (_initialized && _ttsState == TtsState.playing) {
      _ttsState = TtsState.paused;
      await _flutterTts.pause();
    }
  }

  Future<void> stop() async {
    if (_initialized) {
      _ttsState = TtsState.stopped;
      await _flutterTts.stop();
    }
  }

  TtsState get state => _ttsState;

  void dispose() {
    stop();
    _ttsCompletionController.close();
    _ttsErrorController.close();
    _ttsStartController.close();
    _ttsProgressController.close();
  }
}
