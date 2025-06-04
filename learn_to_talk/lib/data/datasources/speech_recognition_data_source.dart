import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_speech/google_speech.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Define a custom class to match the old SpeechRecognitionResult interface
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

class SpeechRecognitionDataSource {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  late SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _isListening = false;
  StreamSubscription? _audioStreamSubscription;
  StreamSubscription? _recorderSubscription;
  String? _recordingPath;
  final StreamController<Uint8List> _audioStreamController = StreamController<Uint8List>();
  Stream<List<int>> get audioStream => _audioStreamController.stream.map((data) => data.toList());
  
  // Stream controllers for handling speech events
  final _recognitionResultsController = StreamController<RecognitionResult>.broadcast();
  final _recognitionErrorController = StreamController<String>.broadcast();
  final _listeningStatusController = StreamController<bool>.broadcast();
  
  // Expose streams for listeners
  Stream<RecognitionResult> get recognitionResults => _recognitionResultsController.stream;
  Stream<String> get recognitionErrors => _recognitionErrorController.stream;
  Stream<bool> get listeningStatus => _listeningStatusController.stream;

  Future<void> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }
      
      // Initialize the recorder
      await _recorder.openRecorder();
      _speechEnabled = true;
      print('Speech recognition initialized successfully');
    } catch (e) {
      _speechEnabled = false;
      print('Failed to initialize speech recognition: $e');
      _recognitionErrorController.add('Failed to initialize speech recognition: $e');
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    if (!_speechEnabled) {
      await initialize();
    }
    
    // Google Speech API supports these major languages
    // This is a simplified list - in a real app, you might fetch this from a config file
    return [
      'en-US',  // English (US)
      'en-GB',  // English (UK)
      'es-ES',  // Spanish
      'fr-FR',  // French
      'de-DE',  // German
      'it-IT',  // Italian
      'pt-BR',  // Portuguese (Brazil)
      'ru-RU',  // Russian
      'zh-CN',  // Chinese (Simplified)
      'ja-JP',  // Japanese
      'ko-KR',  // Korean
    ];
  }

  Future<bool> startListening(String languageCode) async {
    if (!_speechEnabled) {
      await initialize();
    }
    
    if (_isListening) {
      await stopListening();
    }
    
    try {
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
        languageCode: languageCode,
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
      
      _isListening = true;
      _listeningStatusController.add(true);
      
      // Process the audio stream with Google Speech API
      final responseStream = _speechToText.streamingRecognize(
        StreamingRecognitionConfig(config: config, interimResults: true),
        audioStream,
      );
      
      // Listen to recognition results
      _audioStreamSubscription = responseStream.listen((data) {
        if (data.results.isNotEmpty) {
          final result = data.results.first;
          if (result.alternatives.isNotEmpty) {
            final text = result.alternatives.first.transcript;
            final confidence = result.alternatives.first.confidence;
            
            _recognitionResultsController.add(RecognitionResult(
              recognizedWords: text,
              finalResult: result.isFinal,
              confidence: confidence,
            ));
          }
        }
      }, onError: (error) {
        _recognitionErrorController.add("Recognition error: $error");
        stopListening();
      });
      
      return true;
    } catch (e) {
      _recognitionErrorController.add("Failed to start listening: $e");
      _isListening = false;
      _listeningStatusController.add(false);
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }
      
      if (_recorderSubscription != null) {
        await _recorderSubscription!.cancel();
        _recorderSubscription = null;
      }
      
      if (_audioStreamSubscription != null) {
        await _audioStreamSubscription!.cancel();
        _audioStreamSubscription = null;
      }
      
      // Clean up temporary file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (file.existsSync()) {
          await file.delete();
        }
        _recordingPath = null;
      }
    } catch (e) {
      _recognitionErrorController.add("Error stopping listening: $e");
    } finally {
      _isListening = false;
      _listeningStatusController.add(false);
    }
  }

  bool isListening() {
    return _isListening;
  }

  Future<void> dispose() async {
    if (_isListening) {
      await stopListening();
    }
    
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
    
    await _recorder.closeRecorder();
    await _audioStreamController.close();
    await _recognitionResultsController.close();
    await _recognitionErrorController.close();
    await _listeningStatusController.close();
  }
}
