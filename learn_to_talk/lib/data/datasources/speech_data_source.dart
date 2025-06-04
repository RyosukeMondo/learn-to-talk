import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_speech/google_speech.dart';
import 'package:learn_to_talk/data/models/language_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechDataSource {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  late StreamSubscription _audioStreamSubscription;
  late StreamSubscription _recorderSubscription;
  late SpeechToText _speechToText;
  bool _isInitialized = false;
  bool _isRecognizing = false;
  String _languageCode = 'en-US';
  String? _recordingPath;
  final StreamController<Uint8List> _audioStreamController = StreamController<Uint8List>();
  Stream<List<int>> get audioStream => _audioStreamController.stream.map((data) => data.toList());
  
  final _recognitionResultsController = StreamController<String>.broadcast();
  final _recognitionErrorsController = StreamController<String>.broadcast();

  Stream<String> get recognitionResults => _recognitionResultsController.stream;
  Stream<String> get recognitionErrors => _recognitionErrorsController.stream;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }
      
      // Initialize recorder
      await _recorder.openRecorder();
      _isInitialized = true;
      return true;
    } catch (e) {
      _recognitionErrorsController.add("Failed to initialize: $e");
      return false;
    }
  }

  Future<bool> isRecognitionAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  Future<List<LanguageModel>> getSpeechRecognitionLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Google Speech API supports these major languages
    // For a complete list, see: https://cloud.google.com/speech-to-text/docs/languages
    final supportedLanguages = [
      {'code': 'en-US', 'name': 'English (US)'},
      {'code': 'en-GB', 'name': 'English (UK)'},
      {'code': 'es-ES', 'name': 'Spanish'},
      {'code': 'fr-FR', 'name': 'French'},
      {'code': 'de-DE', 'name': 'German'},
      {'code': 'it-IT', 'name': 'Italian'},
      {'code': 'pt-BR', 'name': 'Portuguese (Brazil)'},
      {'code': 'ru-RU', 'name': 'Russian'},
      {'code': 'zh-CN', 'name': 'Chinese (Simplified)'},
      {'code': 'ja-JP', 'name': 'Japanese'},
      {'code': 'ko-KR', 'name': 'Korean'},
    ];
    
    return supportedLanguages.map((lang) => LanguageModel(
      code: lang['code']!,
      name: lang['name']!,
      isOfflineAvailable: false, // Google Speech API is cloud-based
    )).toList();
  }

  Future<bool> isLanguageAvailableForOfflineRecognition(String languageCode) async {
    // Google Speech is cloud-based, so offline recognition is not available
    return false;
  }

  Future<void> startRecognition(String languageCode) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isRecognizing) {
      await stopRecognition();
    }
    
    _languageCode = languageCode;
    _isRecognizing = true;
    
    // Initialize SpeechToText with the selected language
    _speechToText = SpeechToText.viaServiceAccount(
      ServiceAccount.fromString(
        // In a real app, this would be stored securely or fetched from server
        // For demo purposes, we'll just use a placeholder
        r'''{"type":"service_account","project_id":"your-project-id"}''',
      ),
    );
    
    // Configure recognition
    final config = RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.basic,
      enableAutomaticPunctuation: true,
      sampleRateHertz: 16000,
      languageCode: _languageCode,
    );
    
    // Create temp file for recording
    final tempDir = await getTemporaryDirectory();
    _recordingPath = '${tempDir.path}/audio_recording.pcm';
    
    // Start recording
    await _recorder.startRecorder(
      toFile: _recordingPath,
      codec: Codec.pcm16,
      sampleRate: 16000,
    );
    
    // Set up recording stream
    _recorderSubscription = _recorder.onProgress!.listen((event) {
      if (event.duration.inMilliseconds > 100) {
        // Process recorded audio in chunks
        final file = File(_recordingPath!);
        if (file.existsSync()) {
          try {
            final bytes = file.readAsBytesSync();
            _audioStreamController.add(bytes);
          } catch (e) {
            print('Error reading recording file: $e');
          }
        }
      }
    });
    
    // Process the audio stream with Google Speech API
    final responseStream = _speechToText.streamingRecognize(
      StreamingRecognitionConfig(config: config, interimResults: true),
      audioStream,
    );
    
    // Listen to recognition results
    _audioStreamSubscription = responseStream.listen((data) {
      final result = data.results.first;
      if (result.alternatives.isNotEmpty) {
        final text = result.alternatives.first.transcript;
        if (result.isFinal) {
          _recognitionResultsController.add(text);
        }
      }
    }, onError: (error) {
      _recognitionErrorsController.add("Recognition error: $error");
      stopRecognition();
    });
  }

  Future<void> stopRecognition() async {
    if (!_isRecognizing) return;
    
    _isRecognizing = false;
    
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
    
    await _audioStreamSubscription.cancel();
    
    await _recorderSubscription.cancel();
    
    // Clean up temporary file
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (file.existsSync()) {
        await file.delete();
      }
      _recordingPath = null;
    }
  }

  Future<void> dispose() async {
    if (_isRecognizing) {
      await stopRecognition();
    }
    
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
    
    await _recorder.closeRecorder();
    await _audioStreamController.close();
    await _recognitionResultsController.close();
    await _recognitionErrorsController.close();
  }
}
